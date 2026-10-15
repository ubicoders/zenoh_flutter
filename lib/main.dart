import 'package:flutter/material.dart';
import 'package:zenoh_flutter/pages/settings_page.dart';
import 'package:zenoh_flutter/pages/topics_page.dart';
import 'package:zenoh_flutter/pages/viewer_page.dart';
import 'package:zenoh_flutter/session/session_controller.dart';
import 'package:zenoh_flutter/session/session_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SessionController.instance.settings = await SessionSettings.load();
  runApp(const ZenohApp());
}

class ZenohApp extends StatelessWidget {
  const ZenohApp({super.key});

  static ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenoh',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: '/settings',
      routes: {
        '/settings': (_) => const SettingsPage(),
        '/topics': (_) => const TopicsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/view') {
          final keyExpr = settings.arguments as String;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ViewerPage(keyExpr: keyExpr),
          );
        }
        return null;
      },
    );
  }
}
