import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/session/log_entry.dart';
import 'package:zenoh_flutter/session/session_settings.dart';

enum SessionState { disconnected, connecting, connected, error }

/// Owns the single app-wide Zenoh session and the system event log.
class SessionController extends ChangeNotifier {
  SessionController._();

  static final SessionController instance = SessionController._();

  static const int maxLogs = 2000;

  /// Edited in place by the Settings page; loaded in main() before runApp.
  SessionSettings settings = SessionSettings.defaults();

  SessionState _state = SessionState.disconnected;
  ZenohClient? _client;
  String? _errorText;
  String? _connectedSummary;
  final List<LogEntry> _logs = [];
  int _generation = 0;
  bool _notifyScheduled = false;

  SessionState get state => _state;

  /// Non-null iff [state] is [SessionState.connected].
  ZenohClient? get client => _state == SessionState.connected ? _client : null;

  String? get errorText => _errorText;

  /// The settings summary captured when the session opened, else the state.
  String get summary => _state == SessionState.connected
      ? (_connectedSummary ?? settings.summary)
      : _state.name;

  /// Newest first.
  List<LogEntry> get logs => UnmodifiableListView(_logs);

  void log(String message, {bool isError = false}) {
    _logs.insert(
      0,
      LogEntry(timestamp: DateTime.now(), message: message, isError: isError),
    );
    if (_logs.length > maxLogs) _logs.removeRange(maxLogs, _logs.length);
    debugPrint(isError ? 'ZERR: $message' : 'ZSYS: $message');
    _notify();
  }

  void clearLogs() {
    _logs.clear();
    _notify();
  }

  /// Closes any open session, then opens one from [settings].
  Future<void> open() async {
    final generation = ++_generation;
    final previous = _client;
    _client = null;
    _connectedSummary = null;
    _errorText = null;
    _state = SessionState.connecting;
    _notify();

    if (previous != null) {
      log('Closing previous session');
      await _closeClient(previous);
    }

    try {
      await settings.save();
    } catch (e) {
      log('Could not save settings: $e', isError: true);
    }

    final summary = settings.summary;
    final config = settings.toZenohConfig();
    log('Opening $summary  ${jsonEncode(config.toJson())}');

    try {
      final client = await ZenohClient.connect(config);
      if (generation != _generation) {
        // close() or another open() ran while we were connecting.
        await _closeClient(client);
        return;
      }
      _client = client;
      _connectedSummary = summary;
      _state = SessionState.connected;
      log('Session open · $summary');
    } catch (e) {
      _fail(generation, e);
    }
  }

  Future<void> close() async {
    _generation++;
    final client = _client;
    _client = null;
    _connectedSummary = null;
    _errorText = null;
    _state = SessionState.disconnected;
    _notify();
    if (client != null) await _closeClient(client);
    log('Session closed');
  }

  void _fail(int generation, Object error) {
    if (generation != _generation) return;
    _state = SessionState.error;
    _errorText = error.toString();
    log('Open failed: $error', isError: true);
  }

  Future<void> _closeClient(ZenohClient client) async {
    try {
      if (!client.isClosed) await client.close();
    } catch (e) {
      log('Close failed: $e', isError: true);
    }
  }

  /// Defers notification when called during a build (e.g. from initState).
  void _notify() {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduler.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
}
