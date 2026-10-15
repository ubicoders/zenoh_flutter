import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/topics/payload_type.dart';
import 'package:zenoh_flutter/topics/rate_counter.dart';

/// What discovery knows about one key expression.
class TopicInfo {
  TopicInfo._(this.keyExpr, this.lastSeen);

  final String keyExpr;

  /// Sniffed from the first non-empty sample and then cached.
  PayloadType? type;
  int lastSize = 0;
  DateTime lastSeen;
  final RateCounter rate = RateCounter();
  bool _typeFromEmpty = false;

  /// No sample for [TopicRegistry.staleAfter] or longer.
  bool isStale([DateTime? now]) =>
      (now ?? DateTime.now()).difference(lastSeen) >= TopicRegistry.staleAfter;

  void _record(ZenohSample sample, DateTime now) {
    rate.tick(now);
    lastSize = sample.payload.length;
    lastSeen = now;
    if (type == null || _typeFromEmpty) {
      type = detectPayloadType(sample.payload, encoding: sample.encoding);
      _typeFromEmpty = sample.payload.isEmpty;
    }
  }
}

/// App-wide topic discovery: one subscriber on the configured discovery
/// scope that records every distinct key expression it sees.
///
/// Stays alive across page changes; tears itself down (and forgets all
/// topics) when the session leaves [SessionState.connected], and restarts
/// on reconnect if [start] had been requested.
class TopicRegistry extends ChangeNotifier {
  TopicRegistry._() {
    final session = SessionController.instance;
    _lastState = session.state;
    _lastClient = session.client;
    session.addListener(_onSession);
  }

  static final TopicRegistry instance = TopicRegistry._();

  /// Rows not seen for this long are drawn dimmed.
  static const Duration staleAfter = Duration(seconds: 10);

  /// Rows not seen for this long are removed.
  static const Duration expireAfter = Duration(seconds: 60);

  static const Duration _notifyInterval = Duration(milliseconds: 250);
  static const Duration _sweepInterval = Duration(seconds: 2);

  final Map<String, TopicInfo> _topics = {};
  List<TopicInfo>? _sorted;

  ZenohClient? _client;
  ZenohSubscriber? _subscriber;
  StreamSubscription<ZenohSample>? _streamSub;
  String? _scope;
  DateTime? _startedAt;
  bool _running = false;
  bool _starting = false;
  bool _wanted = false;
  bool _startAgain = false;
  int _generation = 0;

  Timer? _notifyTimer;
  Timer? _sweepTimer;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  late SessionState _lastState;
  ZenohClient? _lastClient;

  /// Known topics, sorted by key expression.
  List<TopicInfo> get topics => _sorted ??= List.unmodifiable(
    _topics.values.toList()..sort((a, b) => a.keyExpr.compareTo(b.keyExpr)),
  );

  /// True while the discovery subscriber is declared and its stream is open.
  bool get running => _running;

  /// True while a [start] is declaring the discovery subscriber.
  bool get starting => _starting;

  /// The key expression discovery listens on (null before the first start).
  String? get scope => _scope;

  /// When the current discovery subscriber was declared.
  DateTime? get startedAt => _startedAt;

  /// Starts discovery on the current session (idempotent).
  ///
  /// Does nothing when not connected, but remembers the request so discovery
  /// starts as soon as the session connects. Restarts when the scope in the
  /// settings or the session's client changed since the last start.
  Future<void> start() async {
    _wanted = true;
    if (_starting) {
      _startAgain = true; // re-evaluate once the in-flight start finishes
      return;
    }
    final session = SessionController.instance;
    final client = session.client;
    if (client == null) return;
    final scope = _currentScope();
    if (_running && identical(client, _client) && scope == _scope) return;

    _starting = true;
    try {
      await _teardown();
      if (!_wanted || !identical(session.client, client)) return;
      if (scope != _scope) {
        _topics.clear();
        _sorted = null;
      }
      final generation = _generation;
      final subscriber = await client.subscribe(scope);
      if (generation != _generation ||
          !_wanted ||
          !identical(session.client, client)) {
        // stop() or a session change happened while we were declaring.
        await _undeclare(client, subscriber);
        return;
      }
      _client = client;
      _subscriber = subscriber;
      _scope = scope;
      _startedAt = DateTime.now();
      _running = true;
      _streamSub = subscriber.stream.listen(
        _onSample,
        onError: (Object e) =>
            session.log('Discovery error: $e', isError: true),
        onDone: () => _onStreamDone(subscriber),
      );
      _sweepTimer = Timer.periodic(_sweepInterval, (_) => _sweep());
      session.log('Discovery listening on $scope');
    } catch (e) {
      session.log('Discovery subscribe on "$scope" failed: $e', isError: true);
    } finally {
      _starting = false;
      _notifyNow();
      if (_startAgain) {
        _startAgain = false;
        if (_wanted) unawaited(start());
      }
    }
  }

  /// Stops discovery and no longer restarts it on reconnect.
  /// Known topics are kept until they expire or the session ends.
  Future<void> stop() async {
    _wanted = false;
    await _teardown();
    _notifyNow();
  }

  String _currentScope() {
    final scope = SessionController.instance.settings.discoveryScope.trim();
    return scope.isEmpty ? '**' : scope;
  }

  void _onSession() {
    final session = SessionController.instance;
    final state = session.state;
    final client = session.client;
    final changed = state != _lastState || !identical(client, _lastClient);
    _lastState = state;
    _lastClient = client;
    if (!changed) return;

    if (state != SessionState.connected) {
      final hadAnything = _running || _subscriber != null || _topics.isNotEmpty;
      unawaited(_teardown());
      _topics.clear();
      _sorted = null;
      if (hadAnything) _notifyNow();
    } else if (_wanted) {
      unawaited(start());
    }
  }

  void _onSample(ZenohSample sample) {
    final now = DateTime.now();
    var info = _topics[sample.keyExpr];
    if (info == null) {
      info = TopicInfo._(sample.keyExpr, now);
      _topics[sample.keyExpr] = info;
      _sorted = null;
    }
    info._record(sample, now);
    _scheduleNotify();
  }

  void _onStreamDone(ZenohSubscriber subscriber) {
    if (!identical(subscriber, _subscriber)) return;
    SessionController.instance.log(
      'Discovery stream on ${_scope ?? '?'} closed',
      isError: true,
    );
    // The stream ended underneath us (usually the session closing). Drop our
    // references without undeclaring: the native side is already gone and a
    // second undeclare would free it twice.
    _generation++;
    _sweepTimer?.cancel();
    _sweepTimer = null;
    _streamSub = null;
    _subscriber = null;
    _client = null;
    _running = false;
    _notifyNow();
  }

  /// Cancels the stream and undeclares the discovery subscriber, if any.
  Future<void> _teardown() async {
    _generation++;
    _sweepTimer?.cancel();
    _sweepTimer = null;
    final streamSub = _streamSub;
    final subscriber = _subscriber;
    final client = _client;
    _streamSub = null;
    _subscriber = null;
    _client = null;
    _running = false;
    // Cancel and undeclare synchronously (before any await) so both happen
    // before a pending client.close().
    final cancelled = streamSub?.cancel();
    if (subscriber != null && client != null) {
      await _undeclare(client, subscriber);
    }
    try {
      await cancelled;
    } catch (_) {}
  }

  Future<void> _undeclare(ZenohClient client, ZenohSubscriber sub) async {
    if (client.isClosed) return; // close() already released it
    try {
      await client.undeclareSubscriber(sub);
    } catch (e) {
      SessionController.instance.log(
        'Discovery undeclare failed: $e',
        isError: true,
      );
    }
  }

  void _sweep() {
    final now = DateTime.now();
    final before = _topics.length;
    _topics.removeWhere((_, t) => now.difference(t.lastSeen) >= expireAfter);
    if (_topics.length != before) {
      _sorted = null;
      _notifyNow();
    }
  }

  /// Coalesces per-sample changes into at most one notification per
  /// [_notifyInterval].
  void _scheduleNotify() {
    if (_notifyTimer != null) return;
    final wait = _notifyInterval - DateTime.now().difference(_lastNotify);
    if (wait <= Duration.zero) {
      _notifyNow();
    } else {
      _notifyTimer = Timer(wait, _notifyNow);
    }
  }

  void _notifyNow() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    _lastNotify = DateTime.now();
    notifyListeners();
  }
}
