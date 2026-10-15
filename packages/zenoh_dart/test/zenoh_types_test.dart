import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zenoh_dart/src/zenoh_types.dart';

void main() {
  group('ZenohConfig', () {
    test('produces json with defaults', () {
      final config = ZenohConfig();
      expect(config.toJson(), equals({'mode': ZenohMode.peer.name}));
    });

    test('includes locator when provided', () {
      final config =
          // ignore: deprecated_member_use_from_same_package
          ZenohConfig(mode: ZenohMode.client, locator: 'tcp/localhost:7447');
      expect(
        config.toJson(),
        equals({
          'mode': 'client',
          'connect': {
            'endpoints': ['tcp/localhost:7447'],
          },
        }),
      );
    });

    test('client with one connect endpoint', () {
      final config = ZenohConfig(
        mode: ZenohMode.client,
        connectEndpoints: const ['tcp/10.0.2.2:7447'],
      );
      expect(
        config.toJson(),
        equals({
          'mode': 'client',
          'connect': {
            'endpoints': ['tcp/10.0.2.2:7447'],
          },
        }),
      );
    });

    test('router with listen endpoints and multicast scouting disabled', () {
      final config = ZenohConfig(
        mode: ZenohMode.router,
        listenEndpoints: const ['tcp/0.0.0.0:7447', 'ws/0.0.0.0:8000'],
        multicastScouting: false,
      );
      expect(
        config.toJson(),
        equals({
          'mode': 'router',
          'listen': {
            'endpoints': ['tcp/0.0.0.0:7447', 'ws/0.0.0.0:8000'],
          },
          'scouting': {
            'multicast': {'enabled': false},
          },
        }),
      );
    });

    test('peer with nothing set emits only mode', () {
      final config = ZenohConfig(mode: ZenohMode.peer);
      expect(config.toJson(), equals({'mode': 'peer'}));
    });
  });

  group('ZenohSample', () {
    test('retains key expression and payload bytes', () {
      final payload = Uint8List.fromList(const [1, 2, 3]);
      final sample = ZenohSample(keyExpr: 'demo', payload: payload);

      expect(sample.keyExpr, 'demo');
      expect(sample.payload, same(payload));
    });

    test('decodes payload as string using utf8 by default', () {
      final sample = ZenohSample(
        keyExpr: 'demo',
        payload: Uint8List.fromList('zenoh'.codeUnits),
      );

      expect(sample.payloadAsString(), 'zenoh');
    });
  });
}
