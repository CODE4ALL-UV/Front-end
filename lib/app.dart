import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/users_management/screens/login_screen.dart';
import 'ui/users_management/screens/login_dark_screen.dart';
import 'ui/users_management/screens/form_light_screen.dart';
import 'ui/users_management/screens/form_dark_screen.dart';
import 'ui/users_management/screens/learning_module_light_screen.dart';
import 'ui/users_management/screens/learning_module_dark_screen.dart';

// Definimos los 6 estados de tema posibles de tu TG
enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

enum AppScreen { login, register, modulo }

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Inicializamos en tema claro y pantalla de login
  AppThemeMode _currentThemeMode = AppThemeMode.light;
  AppScreen _currentScreen = AppScreen.login;

  void _goToRegister() => setState(() => _currentScreen = AppScreen.register);
  void _goToLogin() => setState(() => _currentScreen = AppScreen.login);
  void _goToModulo() => setState(() => _currentScreen = AppScreen.modulo);

  void _handleSuccessfulLogin(String role) {
    if (role.toLowerCase() == 'estudiante') {
      _goToModulo();
      return;
    }

    _goToLogin();
  }

  // Método auxiliar para obtener el ThemeData dinámicamente según la selección
  ThemeData _getThemeData() {
    switch (_currentThemeMode) {
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.protanopia:
        return AppTheme.protanopiaTheme;
      case AppThemeMode.deuteranopia:
        return AppTheme.deuteranopiaTheme;
      case AppThemeMode.tritanopia:
        return AppTheme.tritanopiaTheme;
      case AppThemeMode.achromatopsia:
        return AppTheme.achromatopsiaTheme;
      case AppThemeMode.light:
        return AppTheme.lightTheme;
    }
  }

  // Ciclo rotativo de prueba para el botón (Claro -> Oscuro -> Deuteranopía -> Claro...)
  void _toggleTheme() {
    setState(() {
      if (_currentThemeMode == AppThemeMode.light) {
        _currentThemeMode = AppThemeMode.dark;
      } else if (_currentThemeMode == AppThemeMode.dark) {
        _currentThemeMode = AppThemeMode.deuteranopia;
      } else {
        _currentThemeMode = AppThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;

    switch (_currentScreen) {
      case AppScreen.register:
        currentPage = _currentThemeMode == AppThemeMode.dark
            ? FormPageDark(onBack: _goToLogin, onSuccess: _goToLogin)
            : FormPageLight(onBack: _goToLogin, onSuccess: _goToLogin);
        break;
      case AppScreen.modulo:
        currentPage = _currentThemeMode == AppThemeMode.dark
            ? const ModuloAprendizajeDark()
            : const ModuloAprendizaje();
        break;
      case AppScreen.login:
        currentPage = _currentThemeMode == AppThemeMode.dark
            ? LoginPageDark(
                onRegister: _goToRegister,
                onSuccess: _handleSuccessfulLogin,
              )
            : LoginPage(
                onRegister: _goToRegister,
                onSuccess: _handleSuccessfulLogin,
              );
        break;
    }

    return MaterialApp(
      title: 'Code4All',
      debugShowCheckedModeBanner: false,
      theme: _getThemeData(),
      home: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey('${_currentScreen.name}_${_currentThemeMode.name}'),
              child: currentPage,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: Semantics(
              button: true,
              label: 'Cambiar tema',
              hint: 'Cambia el tema de la aplicación',
              child: FloatingActionButton(
                heroTag: 'theme-toggle',
                backgroundColor: const Color(0xFF5C6BC0),
                onPressed: _toggleTheme,
                child: const Icon(Icons.palette, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
