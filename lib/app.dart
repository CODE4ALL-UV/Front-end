import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'features/gestion_usuarios/views/login_page.dart';
import 'features/gestion_usuarios/views/login_page_dark.dart';
import 'features/gestion_usuarios/views/form_page_light.dart';
import 'features/gestion_usuarios/views/form_page_dark.dart';
import 'features/gestion_usuarios/views/modulo_aprendizaje_light.dart';
import 'features/gestion_usuarios/views/modulo_aprendizaje_dark.dart';

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
      default:
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
    // 1. Le asignamos una pantalla por defecto desde el inicio
    // 2. Control de navegación unificado (Una sola pantalla por feature)
    Widget currentPage = LoginPage(onRegister: _goToRegister);

    switch (_currentScreen) {
      case AppScreen.register:
        //currentPage = RegisterPage(onBack: _goToLogin, onSuccess: _goToModulo);
        break;
      case AppScreen.modulo:
        //currentPage = const ModuloAprendizajePage();
        break;
      case AppScreen.login:
      default:
        currentPage = LoginPage(onRegister: _goToRegister);
        break;
    }

    return MaterialApp(
      title: 'Code4All',
      debugShowCheckedModeBanner: false,

      // 3. INYECTAMOS EL TEMA DINÁMICO AQUÍ
      theme: _getThemeData(),

      // Eliminamos el Scaffold global de aquí. Cada página (Login, Registro) debe
      // tener su propio Scaffold para poder usar el HeaderWidget de forma independiente.
      home: Scaffold(
        body: currentPage,
        floatingActionButton: Semantics(
          button: true,
          label: 'Cambiar modo visual de la aplicación',
          hint:
              'Alterna entre modo claro, modo oscuro y contrastes de daltonismo.',
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF5C6BC0),
            onPressed: _toggleTheme,
            child: const Icon(Icons.palette, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
