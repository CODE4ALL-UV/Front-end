import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/ui/accessibility_text_scale.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'ui/users_management/screens/login_screen.dart';
import 'ui/users_management/screens/login_dark_screen.dart';
import 'ui/users_management/screens/form_light_screen.dart';
import 'ui/users_management/screens/form_dark_screen.dart';
import 'ui/users_management/screens/learning_module_light_screen.dart';
import 'ui/users_management/screens/learning_module_dark_screen.dart';
import 'ui/director/director_performance_screen.dart';

// Definimos los 6 estados de tema posibles de tu TG
enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

enum AppScreen { login, register, modulo, director }

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Inicializamos en tema claro y pantalla de login
  AppThemeMode _currentThemeMode = AppThemeMode.light;
  AppScreen _currentScreen = AppScreen.login;
  String _userName = 'Usuario';
  List<String> _bottomLabels = ['Anterior', 'Reproducir', 'Siguiente'];
  final AccessibilityTextScaleController _textScaleController =
      AccessibilityTextScaleController.global;

  @override
  void initState() {
    super.initState();
    _textScaleController.addListener(_handleTextScaleChanged);
  }

  @override
  void dispose() {
    _textScaleController.removeListener(_handleTextScaleChanged);
    super.dispose();
  }

  void _handleTextScaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToRegister() => setState(() => _currentScreen = AppScreen.register);
  void _goToLogin() => setState(() => _currentScreen = AppScreen.login);
  void _goToModulo() => setState(() => _currentScreen = AppScreen.modulo);

  void _handleSuccessfulLogin(String role) {
    final r = role.toLowerCase();
    if (r == 'estudiante' || r == 'docente') {
      _goToModulo();
      return;
    }
    if (r == 'director') {
      setState(() => _currentScreen = AppScreen.director);
      return;
    }

    _goToLogin();
  }

  void _handleUserNameChanged(String name) {
    setState(() {
      _userName = name.trim().isNotEmpty ? name : 'Usuario';
    });
  }

  Future<void> _updateUserNameFromStorage() async {
    final storage = AuthStorage();
    final name = await storage.getName();
    if (!mounted) return;
    _handleUserNameChanged(name ?? 'Usuario');
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

  Widget _buildScaledModulePage(BuildContext context, Widget page) {
    if (_currentScreen != AppScreen.modulo) {
      return page;
    }

    final scale = _textScaleController.scale;
    if (scale <= 1.0) {
      return page;
    }

    final screenSize = MediaQuery.of(context).size;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topCenter,
      child: SizedBox(width: screenSize.width / scale, child: page),
    );
  }

  // Mostrar selector con tres opciones y actualizar etiquetas
  void _showThemeOptions(BuildContext context) async {
    final choice = await showModalBottomSheet<AppThemeMode>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Claro'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.light),
              ),
              ListTile(
                title: const Text('Oscuro'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.dark),
              ),
              ListTile(
                title: const Text('Accesibilidad'),
                subtitle: const Text('Deuteranopía'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.deuteranopia),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    setState(() {
      _currentThemeMode = choice;
      if (choice == AppThemeMode.light) {
        _bottomLabels = ['Anterior', 'Reproducir', 'Siguiente'];
      } else if (choice == AppThemeMode.dark) {
        _bottomLabels = ['Volver', 'Play', 'Adelantar'];
      } else {
        _bottomLabels = ['Atrás', 'Iniciar', 'Siguiente'];
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
            ? ModuloAprendizajeDark(
                userName: _userName,
                bottomLabels: _bottomLabels,
              )
            : ModuloAprendizaje(
                userName: _userName,
                onLogout: _goToLogin,
                bottomLabels: _bottomLabels,
              );
        break;
      case AppScreen.director:
        currentPage = _currentThemeMode == AppThemeMode.dark
            ? DirectorPerformanceScreen(onLogout: _goToLogin)
            : DirectorPerformanceScreen(onLogout: _goToLogin);
        break;
      case AppScreen.login:
        currentPage = _currentThemeMode == AppThemeMode.dark
            ? LoginPageDark(
                onRegister: _goToRegister,
                onSuccess: (role) {
                  _handleSuccessfulLogin(role);
                  if (role.toLowerCase() != 'logout') {
                    _updateUserNameFromStorage();
                  }
                },
              )
            : LoginPage(
                onRegister: _goToRegister,
                onSuccess: (role) {
                  _handleSuccessfulLogin(role);
                  if (role.toLowerCase() != 'logout') {
                    _updateUserNameFromStorage();
                  }
                },
              );
        break;
    }

    return AccessibilityTextScaleScope(
      controller: _textScaleController,
      child: MaterialApp(
        title: 'Code4All',
        debugShowCheckedModeBanner: false,
        theme: _getThemeData(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(_textScaleController.scale),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(
                  '${_currentScreen.name}_${_currentThemeMode.name}_${_textScaleController.scale.toStringAsFixed(2)}',
                ),
                child: currentPage,
              ),
            ),
            if (_currentScreen != AppScreen.modulo)
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
                    onPressed: () => _showThemeOptions(context),
                    child: const Icon(Icons.palette, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
