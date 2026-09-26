import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/ui/accessibility_text_scale_widget.dart';
import 'data/services/course_progress_store.dart';
import 'data/services/session_controller.dart';
import 'data/services/learning_analytics_service.dart';
//import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart'; //PAPACHO - ELIMINADO USAR app_theme.dart
import 'ui/core/ui/sign_keyboard_settings.dart';
import 'ui/director/director_home_screen.dart';
import 'ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'ui/users_management/widgets/login_screen.dart';
//import 'ui/users_management/screens/login_dark_screen.dart'; // PAPACHO - ELIMINADO USAR login_screen.dart en pro de app_theme.dart
import 'ui/users_management/widgets/form_screen.dart';
//import 'ui/users_management/screens/form_dark_screen.dart'; // PAPACHO - ELIMINADO USAR form_screen.dart en pro de app_theme.dart
import 'ui/python_course_content/widgets/learning_module_screen.dart'; // MIX - PAPACHO - REFACTOR que reemplaza los otros learning_module_screen light y dark en pro de app_theme.dart

//import 'ui/python_course_content/widgets/learning_module_dark_screen.dart'; // PAPACHO - ELIMINADO USAR learning_module_screen.dart en pro de app_theme.dart

enum AppScreen { login, register, modulo, docente, director }

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppThemeMode _themeMode = AppThemeMode.light;

  /// Para poder vaciar lo que haya apilado al cerrar sesión.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  AppScreen _currentScreen = AppScreen.login;
  String _userName = 'Usuario';

  // NUEVO: Agregamos una variable para saber en qué módulo estamos globalmente.
  // Por defecto es 1 (Azul). Cuando el usuario abra un módulo, debes actualizar esta variable.
  int _currentModuleId = 1;

  // MODIFICADO: (DUDA PAPACHO) Tienes toda la razón. Los textos de los botones
  // no tienen nada que ver con el tema visual. Lo dejamos como una lista fija.
  final List<String> _bottomLabels = const ['Reproducir'];

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
    SessionController.instance.registerLogout(
      _goToLogin,
      navigatorKey: _navigatorKey,
    );

    CourseProgressStore.instance.reportCompletionsTo(
      (sectionId, kind) => LearningAnalyticsService.instance.recordCompletion(
        sectionId: sectionId,
        kind: kind,
      ),
    );

    _textScaleController.addListener(_handleTextScaleChanged);

    // NUEVO: Escuchamos los cambios del ThemeManager
    ThemeManager.themeNotifier.addListener(_onGlobalThemeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshTheme();
      }
    });
  }

  @override
  void dispose() {
    _textScaleController.removeListener(_handleTextScaleChanged);
    // NUEVO: Dejamos de escuchar cuando la app se cierra
    ThemeManager.themeNotifier.removeListener(_onGlobalThemeChanged);
    super.dispose();
  }

  // NUEVO: Método que se ejecuta cada vez que ThemeManager cambia
  void _onGlobalThemeChanged() {
    if (!mounted) return;

    // Wait until the selection event finishes so an open overlay is not
    // synchronously rebuilt while it is handling the tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextThemeMode = ThemeManager.themeNotifier.value;
      if (_themeMode == nextThemeMode) return;
      setState(() {
        _themeMode = nextThemeMode;
      });
    });
  }

  void _handleTextScaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToRegister() => setState(() => _currentScreen = AppScreen.register);
  void _goToLogin() => setState(() => _currentScreen = AppScreen.login);
  void _goToModulo() => setState(() => _currentScreen = AppScreen.modulo);

  // NUEVO: Método para que cuando el usuario entre a un módulo, la app cambie de color.
  void _updateActiveModule(int moduleId) {
    debugPrint('🟢 [APP.DART] Petición para cambiar al módulo: $moduleId');
    if (_currentModuleId != moduleId) {
      setState(() => _currentModuleId = moduleId);
      debugPrint(
        '🟢 [APP.DART] ¡setState ejecutado! _activeModuleId ahora es: $_currentModuleId',
      );
    } else {
      debugPrint('🟡 [APP.DART] Ignorado: El módulo ya era $_currentModuleId');
    }
  }

  void _applyThemeMode(AppThemeMode mode) {
    if (_themeMode == mode) return;

    // Solo le decimos al manager que cambie.
    // Esto automáticamente disparará _onGlobalThemeChanged y actualizará el setState.
    ThemeManager.changeTheme(mode);
  }

  void _refreshTheme() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSuccessfulLogin(String role) {
    // El teclado de dactilología es sólo del estudiante y el ajuste vive en
    // el dispositivo, así que hay que volver a mirar quién entró: sin esto,
    // una sesión de docente heredaría el teclado del estudiante anterior.
    SignKeyboardSettings.instance.refreshSession();

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

  // Mostrar selector con tres opciones y actualizar etiquetas
  // MODIFICADO: Descomentamos las variantes de daltonismo para que puedas probarlas
  void _showThemeOptions(BuildContext context) async {
    final choice = await showModalBottomSheet<AppThemeMode>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Claro'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Oscuro'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.dark),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Deuteranopia (No distintición del Verde)'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.deuteranopia),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Protanopía (No distintición del Rojo)'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.protanopia),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Tritanopía (No distintición del Azul)'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.tritanopia),
              ),
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Acromatopsia (Monocromático)'),
                onTap: () => Navigator.of(ctx).pop(AppThemeMode.achromatopsia),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null) return;
    _applyThemeMode(choice);
  }

  Widget _buildCurrentPage() {
    switch (_currentScreen) {
      case AppScreen.register:
        return FormScreen(onBack: _goToLogin, onSuccess: _goToLogin);
      case AppScreen.modulo:
        return LearningModuleScreen(
          userName: _userName,
          onLogout: _goToLogin,
          bottomLabels: _bottomLabels,
          // ESTO ES LO QUE LOS CONECTA:
          onModuleChanged: _updateActiveModule,
        );
      case AppScreen.docente:
        return TeacherCourseScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.director:
        return DirectorHomeScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.login:
        return LoginScreen(
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
    debugPrint(
      '🏗️ [APP.DART] Haciendo BUILD principal. Módulo activo actual: $_currentModuleId | Filtro daltónico: $_themeMode',
    );
    debugPrint('🟡 [MAIN/APP] Reconstruyendo MaterialApp / Root Widget');
    final activeTheme = AppTheme.getTheme(
      mode: _themeMode,
      moduleId: _currentModuleId,
    );
    final currentPage = _buildCurrentPage();

    return AccessibilityTextScaleScope(
      controller: _textScaleController,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Code4All',
        debugShowCheckedModeBanner: false,
        theme: activeTheme,
        darkTheme: activeTheme,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              // SOBRE EL ERROR: 'textScaler' funciona en Flutter 3.16 o superior.
              // Si tienes una versión anterior de Flutter, comenta la línea de
              // textScaler y usa 'textScaleFactor' en su lugar:
              textScaler: TextScaler.linear(_textScaleController.scale),
              // textScaleFactor: _textScaleController.scale,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_currentScreen.name),
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
                    backgroundColor: activeTheme.colorScheme.primary,
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
