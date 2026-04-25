import 'package:flutter/material.dart';
import 'features/gestion_usuarios/views/login_page_light.dart';
import 'features/gestion_usuarios/views/login_page_dark.dart';
import 'features/gestion_usuarios/views/form_page_light.dart';
import 'features/gestion_usuarios/views/form_page_dark.dart';
import 'features/gestion_usuarios/views/modulo_aprendizaje_light.dart';
import 'features/gestion_usuarios/views/modulo_aprendizaje_dark.dart';

enum AppScreen { login, register, modulo }

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool isDark = false;
  AppScreen _currentScreen = AppScreen.login;

  void _goToRegister() => setState(() => _currentScreen = AppScreen.register);
  void _goToLogin()    => setState(() => _currentScreen = AppScreen.login);
  void _goToModulo()   => setState(() => _currentScreen = AppScreen.modulo);

  @override
  Widget build(BuildContext context) {
    Widget currentPage;

    switch (_currentScreen) {
      case AppScreen.register:
        currentPage = isDark
            ? FormPageDark(onBack: _goToLogin, onSuccess: _goToModulo)
            : FormPageLight(onBack: _goToLogin, onSuccess: _goToModulo);
        break;

      case AppScreen.modulo:
        currentPage = isDark
            ? const ModuloAprendizajeDark()
            : const ModuloAprendizaje();
        break;

      case AppScreen.login:
      default:
        currentPage = isDark
            ? LoginPageDark(onRegister: _goToRegister)
            : LoginPageLight(onRegister: _goToRegister);
        break;
    }

    return MaterialApp(
      title: 'Code4All',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: currentPage,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF5C6BC0),
          onPressed: () => setState(() => isDark = !isDark),
          child: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}