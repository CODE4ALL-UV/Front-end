import 'package:flutter/material.dart';
import 'features/gestion_usuarios/views/login_page_light.dart';
import 'features/gestion_usuarios/views/login_page_dark.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}
s
class _AppState extends State<App> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: isDark ? const LoginPageDark() : const LoginPageLight(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => isDark = !isDark),
          child: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        ),
      ),
    );
  }
}