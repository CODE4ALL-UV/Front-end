import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/ui/accessibility_text_scale.dart';
import 'data/services/course_progress_store.dart';
import 'data/services/session_controller.dart';
import 'data/services/learning_analytics_service.dart';
import 'ui/core/ui/visual_theme_controller.dart';
import 'ui/director/director_home_screen.dart';
import 'ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'ui/users_management/screens/login_screen.dart';
import 'ui/users_management/screens/login_dark_screen.dart';
import 'ui/users_management/screens/form_light_screen.dart';
import 'ui/users_management/screens/form_dark_screen.dart';
import 'ui/python_course_content/widgets/learning_module_light_screen.dart';
import 'ui/python_course_content/widgets/learning_module_dark_screen.dart';

// Definimos los 6 estados de tema posibles de tu TG
enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

enum AppScreen { login, register, modulo, docente, director }

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppScreen _currentScreen = AppScreen.login;
  String _userName = 'Usuario';
  List<String> _bottomLabels = ['Anterior', 'Reproducir', 'Siguiente'];
  final AccessibilityTextScaleController _textScaleController =
      AccessibilityTextScaleController.global;

  @override
  void initState() {
    super.initState();

    // Cada actividad que un estudiante termina pasa por el almacen de
    // progreso. Enganchando aqui el aviso, el curso entero queda registrado
    // sin tocar ninguna pantalla: lecturas, videos, capsulas, ejemplos,
    // ejercicios, quiz, evaluaciones y laboratorio.
    // Cualquier pantalla puede ofrecer cerrar sesion sin recibir nada.
    SessionController.instance.registerLogout(_goToLogin);

    CourseProgressStore.instance.reportCompletionsTo(
      (sectionId, kind) => LearningAnalyticsService.instance.recordCompletion(
        sectionId: sectionId,
        kind: kind,
      ),
    );

    VisualThemeController.globalThemeNotifier.value = false;
    VisualThemeController.globalThemeNotifier.addListener(
      _handleGlobalVisualThemeChanged,
    );
    _textScaleController.addListener(_handleTextScaleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshTheme();
      }
    });
  }

  @override
  void dispose() {
    VisualThemeController.globalThemeNotifier.removeListener(
      _handleGlobalVisualThemeChanged,
    );
    _textScaleController.removeListener(_handleTextScaleChanged);
    super.dispose();
  }

  void _handleTextScaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleGlobalVisualThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _goToRegister() => setState(() => _currentScreen = AppScreen.register);
  void _goToLogin() => setState(() => _currentScreen = AppScreen.login);
  void _goToModulo() => setState(() => _currentScreen = AppScreen.modulo);

  void _applyThemeMode(AppThemeMode mode) {
    final isDarkTheme = mode == AppThemeMode.dark;
    final currentIsDark = VisualThemeController.globalThemeNotifier.value;
    final shouldUpdate =
        currentIsDark != isDarkTheme ||
        mode != AppThemeMode.light && mode != AppThemeMode.dark;

    if (!shouldUpdate) {
      return;
    }

    setState(() {
      VisualThemeController.globalThemeNotifier.value = isDarkTheme;
      if (mode == AppThemeMode.light) {
        _bottomLabels = ['Anterior', 'Reproducir', 'Siguiente'];
      } else if (mode == AppThemeMode.dark) {
        _bottomLabels = ['Volver', 'Play', 'Adelantar'];
      } else {
        _bottomLabels = ['Atrás', 'Iniciar', 'Siguiente'];
      }
    });
  }

  void _handleVisualThemeChanged(bool isDark) {
    _applyThemeMode(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  void _refreshTheme() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSuccessfulLogin(String role) {
    final r = role.toLowerCase();
    if (r == 'estudiante') {
      _goToModulo();
      return;
    }
    // El docente no necesita el mapa de circulos: necesita el temario entero
    // para editarlo.
    if (r == 'docente') {
      setState(() => _currentScreen = AppScreen.docente);
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
  ThemeData _getThemeData(AppThemeMode mode) {
    switch (mode) {
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

    _applyThemeMode(choice);
  }

  Widget _buildCurrentPage(bool isDarkTheme) {
    switch (_currentScreen) {
      case AppScreen.register:
        return isDarkTheme
            ? FormPageDark(onBack: _goToLogin, onSuccess: _goToLogin)
            : FormPageLight(onBack: _goToLogin, onSuccess: _goToLogin);
      case AppScreen.modulo:
        return isDarkTheme
            ? ModuloAprendizajeDark(
                userName: _userName,
                bottomLabels: _bottomLabels,
              )
            : ModuloAprendizaje(
                userName: _userName,
                onLogout: _goToLogin,
                bottomLabels: _bottomLabels,
              );
      case AppScreen.docente:
        return TeacherCourseScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.director:
        return DirectorHomeScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.login:
        return isDarkTheme
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = VisualThemeController.globalThemeNotifier.value;

    return AccessibilityTextScaleScope(
      controller: _textScaleController,
      child: VisualThemeController(
        isDarkTheme: isDarkTheme,
        onThemeChanged: _handleVisualThemeChanged,
        child: ValueListenableBuilder<bool>(
          valueListenable: VisualThemeController.globalThemeNotifier,
          builder: (context, themeValue, _) {
            final effectiveIsDark = themeValue;
            final currentPage = _buildCurrentPage(effectiveIsDark);

            return MaterialApp(
              title: 'Code4All',
              debugShowCheckedModeBanner: false,
              themeMode: effectiveIsDark ? ThemeMode.dark : ThemeMode.light,
              theme: _getThemeData(AppThemeMode.light),
              darkTheme: _getThemeData(AppThemeMode.dark),
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  //HERE IS THE ERROR The relevant error-causing widget failed
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
                        '${_currentScreen.name}_${(effectiveIsDark ? 'dark' : 'light')}',
                      ),
                      child: currentPage,
                    ),
                  ),
                  // Ni el estudiante ni el docente llevan este boton: los dos
                  // tienen su propio sitio para cambiar el tema.
                  if (_currentScreen != AppScreen.modulo &&
                      _currentScreen != AppScreen.docente)
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
            );
          },
        ),
      ),
    );
  }
}
