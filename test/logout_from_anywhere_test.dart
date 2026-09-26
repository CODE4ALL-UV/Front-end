import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/services/session_controller.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';

/// Cerrar sesión tiene que sacar de la aplicación desde donde se esté.
///
/// El riesgo no es que no se llame: es **dónde** se está cuando se llama. La
/// aplicación cambia de pantalla con un `setState` sobre su página de inicio,
/// pero los módulos siguientes, los capítulos y las actividades se abren con
/// `Navigator.push`, así que quedan encima. Si al cerrar sesión solo se cambia
/// la página de abajo, quien esté en el módulo 3 sigue viendo el módulo 3 con
/// el login escondido debajo.
void main() {
  setUp(SessionController.instance.debugReset);
  tearDown(SessionController.instance.debugReset);

  /// Reproduce cómo monta la aplicación sus pantallas: una página de inicio
  /// que cambia con `setState`, y el resto apiladas encima con push.
  Widget app() => const _FakeApp();

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
  }

  testWidgets('desde el módulo de inicio, cerrar sesión lleva al login', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(LearningModuleScreen), findsWidgets);

    SessionController.instance.logout();
    await tester.pumpAndSettle();

    expect(find.text('ESTOY EN EL LOGIN'), findsOneWidget);
    expect(find.byType(LearningModuleScreen), findsNothing);
  });

  testWidgets('desde un módulo abierto encima, también sale', (tester) async {
    await pumpApp(tester);

    // Se avanza al módulo siguiente, que la aplicación abre con push: queda
    // una pantalla encima de la de inicio.
    await tester.tap(find.textContaining('ir al Módulo 2'));
    await tester.pumpAndSettle();

    SessionController.instance.logout();
    await tester.pumpAndSettle();

    expect(
      find.text('ESTOY EN EL LOGIN'),
      findsOneWidget,
      reason: 'con un módulo apilado encima hay que salir igual',
    );
    expect(
      find.byType(LearningModuleScreen),
      findsNothing,
      reason: 'el módulo no puede quedarse encima del login',
    );
  });

  testWidgets('desde tres módulos de profundidad, también sale', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.textContaining('ir al Módulo 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ir al Módulo 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ir al Módulo 4'));
    await tester.pumpAndSettle();

    SessionController.instance.logout();
    await tester.pumpAndSettle();

    expect(
      find.text('ESTOY EN EL LOGIN'),
      findsOneWidget,
      reason: 'la profundidad de la pila no puede dejar a nadie dentro',
    );
    expect(find.byType(LearningModuleScreen), findsNothing);
  });

  testWidgets('sin navegador registrado sigue avisando que se pudo salir', (
    tester,
  ) async {
    // Es el caso de una pantalla suelta en una prueba o en un arranque
    // parcial: no debe reventar, solo no tiene pila que vaciar.
    var salio = false;
    SessionController.instance.registerLogout(() => salio = true);

    expect(SessionController.instance.logout(), isTrue);
    expect(salio, isTrue);
  });
}

/// Imita la estructura de `app.dart`: una página que cambia con `setState` y
/// un `SessionController` registrado para volver al login.
class _FakeApp extends StatefulWidget {
  const _FakeApp();

  @override
  State<_FakeApp> createState() => _FakeAppState();
}

class _FakeAppState extends State<_FakeApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _loggedIn = true;

  @override
  void initState() {
    super.initState();
    // Igual que la aplicación real: se registra cómo salir y con qué
    // navegador vaciar lo que haya apilado encima.
    SessionController.instance.registerLogout(
      _goToLogin,
      navigatorKey: _navigatorKey,
    );
  }

  void _goToLogin() => setState(() => _loggedIn = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: AppTheme.getTheme(mode: AppThemeMode.light),
      home: _loggedIn
          ? const LearningModuleScreen(moduleId: 1)
          : const Scaffold(body: Center(child: Text('ESTOY EN EL LOGIN'))),
    );
  }
}