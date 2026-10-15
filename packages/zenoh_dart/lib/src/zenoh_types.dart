import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'bindings/zenoh_generated.dart' as gen;

/// Session configuration passed to zenoh-c via `zc_config_from_str`.
///
/// [toJson] only emits the keys that were explicitly set, so anything left
/// unset keeps the zenoh default.
class ZenohConfig {
  ZenohConfig({
    this.mode = ZenohMode.peer,
    @Deprecated('Use connectEndpoints') this.locator,
    List<String> connectEndpoints = const [],
    this.listenEndpoints = const [],
    this.multicastScouting,
  }) : connectEndpoints = <String>{
          if (locator != null) locator,
          ...connectEndpoints,
        }.toList();

  final ZenohMode mode;
  final String? locator;

  /// Endpoints to connect to, e.g. 'tcp/10.0.2.2:7447'.
  ///
  /// Includes [locator] (first) when it was provided. Duplicates are removed,
  /// preserving the order of first occurrence.
  final List<String> connectEndpoints;

  /// Endpoints to listen on, e.g. 'tcp/0.0.0.0:7447', 'udp/0.0.0.0:7447',
  /// 'ws/0.0.0.0:8000'.
  final List<String> listenEndpoints;

  /// Enables or disables multicast scouting. null = leave zenoh default.
  final bool? multicastScouting;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'mode': mode.name,
    };
    if (connectEndpoints.isNotEmpty) {
      json['connect'] = <String, Object?>{
        'endpoints': connectEndpoints.toSet().toList(),
      };
    }
    if (listenEndpoints.isNotEmpty) {
      json['listen'] = <String, Object?>{
        'endpoints': listenEndpoints.toSet().toList(),
      };
    }
    final scouting = multicastScouting;
    if (scouting != null) {
      json['scouting'] = <String, Object?>{
        'multicast': <String, Object?>{'enabled': scouting},
      };
    }
    return json;
  }
}

enum ZenohMode {
  peer,
  client,
  router,
}

/// Represents a handle to a Zenoh session.
class ZenohSession {
  ZenohSession(this.pointer);

  final ffi.Pointer<gen.z_owned_session_t> pointer;

  int get handle => pointer.address;
}

/// Represents a sample delivered to subscribers.
class ZenohSample {
  const ZenohSample({
    required this.keyExpr,
    required this.payload,
    this.encoding,
  });

  final String keyExpr;
  final Uint8List payload;

  /// The zenoh encoding of [payload] as produced by `z_encoding_to_string`,
  /// e.g. `text/plain`, `application/json` or `zenoh/bytes`, possibly with a
  /// `;schema` suffix. null when unknown or unavailable.
  final String? encoding;

  String payloadAsString({Encoding encoding = utf8}) =>
      encoding.decode(payload);
}

/// Represents a subscription to a specific resource path.
class ZenohSubscriber {
  ZenohSubscriber(
    this.pointer, {
    required this.stream,
    required this.contextId,
    this.webHandle,
  });

  final ffi.Pointer<gen.z_owned_subscriber_t>? pointer;
  final Stream<ZenohSample> stream;
  final int contextId;
  // Using dynamic for web JSObject to avoid conditional imports
  final dynamic webHandle;

  int get handle => pointer?.address ?? 0;
}

/// Represents a publisher handle for a resource path.
class ZenohPublisher {
  ZenohPublisher(this.pointer, {this.webHandle});

  final ffi.Pointer<gen.z_owned_publisher_t>? pointer;
  // Using dynamic for web JSObject to avoid conditional imports
  final dynamic webHandle;

  int get handle => pointer?.address ?? 0;
}
