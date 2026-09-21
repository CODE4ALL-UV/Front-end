import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/ui/accessibility_text_scale.dart';
import 'data/services/course_progress_store.dart';
import 'data/services/session_controller.dart';
import 'data/services/learning_analytics_service.dart';
//import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart'; //PAPACHO - ELIMINADO USAR app_theme.dart
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

    final newMode = ThemeManager.themeNotifier.value;

    //DUDA PARA PAPACHO
    //Si tus textos van a ser iguales para todos los temas ('Anterior', 'Reproducir', 'Siguiente'),
    //puedes eliminar el switch por completo y dejar la lista estática.
    //Ese switch solo tiene sentido si intencionalmente quieres que las
    //palabras cambien cuando el usuario active el modo oscuro u otro modo.
    setState(() {
      _themeMode = newMode;
      _bottomLabels = switch (newMode) {
        AppThemeMode.dark => ['Volver', 'Play', 'Adelantar'],
        _ => ['Anterior', 'Reproducir', 'Siguiente'],
      };
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
      //   case AppThemeMode.protanopia:
      //     return AppTheme.protanopiaTheme;
      //   case AppThemeMode.deuteranopia:
      //     return AppTheme.deuteranopiaTheme;
      //   case AppThemeMode.tritanopia:
      //     return AppTheme.tritanopiaTheme;
      //   case AppThemeMode.achromatopsia:
      //     return AppTheme.achromatopsiaTheme;
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
              // ListTile(
              //   title: const Text('Deuteranopia'),
              //   onTap: () => Navigator.of(ctx).pop(AppThemeMode.deuteranopia),
              // ),
              // ListTile(
              //   title: const Text('Protanopía'),
              //   onTap: () => Navigator.of(ctx).pop(AppThemeMode.protanopia),
              // ),
              // ListTile(
              //   title: const Text('Tritanopía'),
              //   onTap: () => Navigator.of(ctx).pop(AppThemeMode.tritanopia),
              // ),
              // ListTile(
              //   title: const Text('Acromatopsia'),
              //   onTap: () => Navigator.of(ctx).pop(AppThemeMode.achromatopsia),
              // ),
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
        );
      case AppScreen.docente:
        return TeacherCourseScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.director:
        return DirectorHomeScreen(userName: _userName, onLogout: _goToLogin);
      case AppScreen.login:
        return LoginPage(
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
    final activeTheme = _getThemeData(_themeMode);
    final currentPage = _buildCurrentPage();

    return AccessibilityTextScaleScope(
      controller: _textScaleController,
      child: MaterialApp(
        title: 'Code4All',
        debugShowCheckedModeBanner: false,
        theme: activeTheme,
        // ThemeMode solo entiende claro, oscuro o sistema. La paleta
        // concreta ya fue seleccionada arriba mediante _themeMode.
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
