import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_dart/zenoh_dart.dart';

enum TransportProtocol {
  tcp,
  udp,
  ws;

  int get defaultPort => this == TransportProtocol.ws ? 8000 : 7447;

  static TransportProtocol parse(Object? name) =>
      TransportProtocol.values.asNameMap()[name] ?? TransportProtocol.tcp;
}

/// Ports are 1..65535; 0 (= any free port) only when [allowAny] is true.
bool isValidPort(int port, {bool allowAny = false}) =>
    port >= (allowAny ? 0 : 1) && port <= 65535;

/// One "listen on" row: binds 0.0.0.0 on [port] when [enabled].
class ListenRow {
  ListenRow({required this.protocol, required this.port, this.enabled = false});

  factory ListenRow.fromJson(Map<String, Object?> json) => ListenRow(
    protocol: TransportProtocol.parse(json['protocol']),
    port: _int(json['port'], 0),
    enabled: json['enabled'] == true,
  );

  TransportProtocol protocol;
  int port;
  bool enabled;

  String get locator => '${protocol.name}/0.0.0.0:$port';

  Map<String, Object?> toJson() => {
    'protocol': protocol.name,
    'port': port,
    'enabled': enabled,
  };
}

/// A remote endpoint to connect to, e.g. tcp/10.0.2.2:7447.
class Endpoint {
  Endpoint({required this.protocol, required this.host, required this.port});

  factory Endpoint.fromJson(Map<String, Object?> json) {
    final protocol = TransportProtocol.parse(json['protocol']);
    return Endpoint(
      protocol: protocol,
      host: json['host'] is String ? json['host']! as String : '',
      port: _int(json['port'], protocol.defaultPort),
    );
  }

  TransportProtocol protocol;
  String host;
  int port;

  String get locator => '${protocol.name}/$host:$port';

  bool get isValid => host.trim().isNotEmpty && isValidPort(port);

  /// null when no host was entered, so optional endpoints stay absent.
  Endpoint? get nonEmptyOrNull => host.trim().isEmpty ? null : this;

  Endpoint copy() => Endpoint(protocol: protocol, host: host, port: port);

  Map<String, Object?> toJson() => {
    'protocol': protocol.name,
    'host': host,
    'port': port,
  };
}

/// Everything the Settings page edits. Each mode keeps its own fields so
/// switching modes and back restores what was typed.
class SessionSettings {
  SessionSettings({
    required this.mode,
    required this.discoveryScope,
    required this.clientConnect,
    required this.peerScouting,
    required this.peerConnect,
    required this.peerListen,
    required this.routerListen,
    required this.routerScouting,
    required this.routerConnect,
  });

  factory SessionSettings.defaults() => SessionSettings(
    mode: ZenohMode.peer,
    discoveryScope: '**',
    clientConnect: Endpoint(
      protocol: TransportProtocol.tcp,
      host: defaultHost,
      port: 7447,
    ),
    peerScouting: true,
    peerConnect: null,
    peerListen: _listenRows(tcp: (0, true), udp: (0, true), ws: (8000, true)),
    routerListen: _listenRows(
      tcp: (7447, true),
      udp: (7447, true),
      ws: (8000, false),
    ),
    routerScouting: false,
    routerConnect: [],
  );

  factory SessionSettings.fromJson(Map<String, Object?> json) {
    final d = SessionSettings.defaults();
    return SessionSettings(
      // Missing or unknown mode falls back to peer, like a fresh install.
      mode: ZenohMode.values.asNameMap()[json['mode']] ?? ZenohMode.peer,
      discoveryScope: json['discoveryScope'] is String
          ? json['discoveryScope']! as String
          : d.discoveryScope,
      clientConnect: _endpoint(json['clientConnect']) ?? d.clientConnect,
      peerScouting: json['peerScouting'] is bool
          ? json['peerScouting']! as bool
          : d.peerScouting,
      peerConnect: _endpoint(json['peerConnect'])?.nonEmptyOrNull,
      peerListen: _mergeRows(json['peerListen'], d.peerListen),
      routerListen: _mergeRows(json['routerListen'], d.routerListen),
      routerScouting: json['routerScouting'] is bool
          ? json['routerScouting']! as bool
          : d.routerScouting,
      routerConnect: [
        if (json['routerConnect'] case final List list)
          for (final item in list) ?_endpoint(item),
      ],
    );
  }

  static const prefsKey = 'session_settings_v1';

  /// 10.0.2.2 is the host machine as seen from the Android emulator.
  static String get defaultHost =>
      !kIsWeb && Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

  ZenohMode mode;
  String discoveryScope;

  // client
  Endpoint clientConnect;

  // peer
  bool peerScouting;
  Endpoint? peerConnect;
  List<ListenRow> peerListen;

  // router
  List<ListenRow> routerListen;
  bool routerScouting;
  List<Endpoint> routerConnect;

  ZenohConfig toZenohConfig() => switch (mode) {
    ZenohMode.client => ZenohConfig(
      mode: mode,
      connectEndpoints: [clientConnect.locator],
      multicastScouting: false,
    ),
    ZenohMode.peer => ZenohConfig(
      mode: mode,
      connectEndpoints: [?peerConnect?.nonEmptyOrNull?.locator],
      listenEndpoints: _enabledLocators(peerListen),
      multicastScouting: peerScouting,
    ),
    ZenohMode.router => ZenohConfig(
      mode: mode,
      connectEndpoints: [for (final e in routerConnect) e.locator],
      listenEndpoints: _enabledLocators(routerListen),
      multicastScouting: routerScouting,
    ),
  };

  String get summary {
    final parts = <String>[mode.name];
    switch (mode) {
      case ZenohMode.client:
        parts.add(clientConnect.locator);
      case ZenohMode.peer:
        if (peerScouting) parts.add('scouting');
        if (peerConnect?.nonEmptyOrNull case final e?) parts.add(e.locator);
        // Ephemeral (port 0) listeners are not worth showing.
        final fixed = _listenSummary(peerListen.where((r) => r.port != 0));
        if (fixed.isNotEmpty) parts.add(fixed);
      case ZenohMode.router:
        final listen = _listenSummary(routerListen);
        if (listen.isNotEmpty) parts.add(listen);
        if (routerScouting) parts.add('scouting');
        if (routerConnect.isNotEmpty) {
          parts.add('+${routerConnect.length} connect');
        }
    }
    return parts.join(' · ');
  }

  /// ws runs over TCP, so an enabled ws row may not reuse an enabled tcp
  /// row's port. tcp and udp may share a port.
  static bool wsClashesWithTcp(List<ListenRow> rows) {
    final tcpPorts = {
      for (final r in rows)
        if (r.enabled && r.protocol == TransportProtocol.tcp) r.port,
    };
    return rows.any(
      (r) =>
          r.enabled &&
          r.protocol == TransportProtocol.ws &&
          r.port != 0 &&
          tcpPorts.contains(r.port),
    );
  }

  /// True when the form for the current [mode] can be submitted.
  bool get isValid {
    if (discoveryScope.trim().isEmpty) return false;
    return switch (mode) {
      ZenohMode.client => clientConnect.isValid,
      ZenohMode.peer =>
        (peerConnect?.nonEmptyOrNull?.isValid ?? true) &&
            _rowsValid(peerListen, allowAny: true),
      ZenohMode.router =>
        routerListen.any((r) => r.enabled) &&
            _rowsValid(routerListen, allowAny: false) &&
            routerConnect.every((e) => e.isValid),
    };
  }

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'discoveryScope': discoveryScope,
    'clientConnect': clientConnect.toJson(),
    'peerScouting': peerScouting,
    'peerConnect': peerConnect?.toJson(),
    'peerListen': [for (final r in peerListen) r.toJson()],
    'routerListen': [for (final r in routerListen) r.toJson()],
    'routerScouting': routerScouting,
    'routerConnect': [for (final e in routerConnect) e.toJson()],
  };

  /// The saved settings, or [defaults] when there are none.
  ///
  /// The mode always starts as [ZenohMode.peer], which opens even when no
  /// router is reachable; the fields of every mode (including the client
  /// address) are restored, so switching to client or router gets back what
  /// was last used.
  static Future<SessionSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return SessionSettings.fromJson(decoded.cast<String, Object?>())
            ..mode = ZenohMode.peer;
        }
      }
    } catch (e) {
      debugPrint('Could not load session settings: $e');
    }
    return SessionSettings.defaults();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(toJson()));
  }

  static List<String> _enabledLocators(List<ListenRow> rows) => [
    for (final r in rows)
      if (r.enabled) r.locator,
  ];

  static String _listenSummary(Iterable<ListenRow> rows) => rows
      .where((r) => r.enabled)
      .map((r) => '${r.protocol.name}:${r.port}')
      .join(' ');

  static bool _rowsValid(List<ListenRow> rows, {required bool allowAny}) =>
      rows
          .where((r) => r.enabled)
          .every((r) => isValidPort(r.port, allowAny: allowAny)) &&
      !wsClashesWithTcp(rows);

  static List<ListenRow> _listenRows({
    required (int, bool) tcp,
    required (int, bool) udp,
    required (int, bool) ws,
  }) => [
    ListenRow(protocol: TransportProtocol.tcp, port: tcp.$1, enabled: tcp.$2),
    ListenRow(protocol: TransportProtocol.udp, port: udp.$1, enabled: udp.$2),
    ListenRow(protocol: TransportProtocol.ws, port: ws.$1, enabled: ws.$2),
  ];

  /// Always yields one row per protocol in tcp/udp/ws order.
  static List<ListenRow> _mergeRows(Object? raw, List<ListenRow> defaults) {
    if (raw is! List) return defaults;
    for (final item in raw.whereType<Map>()) {
      final row = ListenRow.fromJson(item.cast<String, Object?>());
      final i = defaults.indexWhere((r) => r.protocol == row.protocol);
      if (i >= 0) defaults[i] = row;
    }
    return defaults;
  }

  static Endpoint? _endpoint(Object? raw) =>
      raw is Map ? Endpoint.fromJson(raw.cast<String, Object?>()) : null;
}

int _int(Object? value, int fallback) =>
    value is num ? value.toInt() : fallback;
