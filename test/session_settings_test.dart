import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenoh_dart/zenoh_dart.dart';
import 'package:zenoh_flutter/session/session_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'load always starts on peer but keeps the saved client address',
    () async {
      final saved = SessionSettings.defaults()
        ..mode = ZenohMode.client
        ..discoveryScope = 'demo/**'
        ..clientConnect.host = '192.168.1.20'
        ..clientConnect.port = 7448;
      SharedPreferences.setMockInitialValues({
        'flutter.${SessionSettings.prefsKey}': jsonEncode(saved.toJson()),
      });

      final loaded = await SessionSettings.load();
      expect(loaded.mode, ZenohMode.peer);
      expect(loaded.discoveryScope, 'demo/**');
      expect(loaded.clientConnect.locator, 'tcp/192.168.1.20:7448');
    },
  );
}
