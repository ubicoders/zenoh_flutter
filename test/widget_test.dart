import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenoh_flutter/pages/settings_page.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/session/session_settings.dart';

void main() {
  testWidgets('Settings page shows the peer session form', (tester) async {
    SessionController.instance.settings = SessionSettings.defaults();

    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    expect(find.text('Session'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Open session'), findsOneWidget);
  });
}
