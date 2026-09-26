import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/services/session_controller.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';

/// Cerrar sesión pulsando **el botón**, no llamando al controlador por dentro.
///
/// La diferencia importa y costó un fallo: `UserProfileMenu` usa el
/// `onLogout` que le pasa la pantalla si lo tiene, y hace `return` antes de
/// llegar a `SessionController`. Las pantallas de módulo sí lo reciben, así
/// que una prueba que llamara al controlador pasaba mientras el botón de
/// verdad seguía sin sacar a nadie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // El almacén seguro no existe en un test, y sin datos de perfil el menú de
  // la cuenta ni siquiera se dibuja: no habría botón que pulsar.
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  late Map<String, String> stored;

  setUp(() {
    stored = {
      'auth_token': 'un-token',
      'auth_role': 'estudiante',
      'auth_name': 'Sebastián',
      'auth_email': 'sebas@code4all-qa.org',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
          final key = args['key']?.toString() ?? '';
          switch (call.method) {
            case 'write':
              stored[key] = args['value']?.toString() ?? '';
              return null;
            case 'read':
              return stored[key];
            case 'delete':
              stored.remove(key);
              return null;
            case 'deleteAll':
              stored.clear();
              return null;
            case 'readAll':
              return stored;
            default:
              return null;
          }
        });
    SessionController.instance.debugReset();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
    SessionController.instance.debugReset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const _FakeApp());
    await tester.pumpAndSettle();
  }

  /// Abre el menú de la cuenta y pulsa «Cerrar sesión».
  Future<void> pulsarCerrarSesion(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
  }

  testWidgets('desde el módulo de inicio, el botón saca al login', (
    tester,
  ) async {
    await pumpApp(tester);

    await pulsarCerrarSesion(tester);

    expect(find.text('ESTOY EN EL LOGIN'), findsOneWidget);
    expect(find.byType(LearningModuleScreen), findsNothing);
  });

  testWidgets('desde el módulo 3, el botón también saca al login', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.textContaining('ir al Módulo 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ir al Módulo 3'));
    await tester.pumpAndSettle();

    await pulsarCerrarSesion(tester);

    expect(
      find.text('ESTOY EN EL LOGIN'),
      findsOneWidget,
      reason: 'era el caso que fallaba: solo salía desde el módulo 1',
    );
    expect(
      find.byType(LearningModuleScreen),
      findsNothing,
      reason: 'el módulo no puede quedarse encima del login',
    );
  });

  testWidgets('la sesión guardada se borra al salir', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.textContaining('ir al Módulo 2'));
    await tester.pumpAndSettle();

    await pulsarCerrarSesion(tester);

    expect(
      stored['auth_token'],
      isNull,
      reason: 'salir sin borrar el token dejaría la sesión viva',
    );
  });
}

/// Imita la estructura de `app.dart`: una página que cambia con `setState`,
/// las siguientes apiladas con push, y el `onLogout` que la aplicación pasa a
/// la pantalla de módulo.
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
          // Con `onLogout`, igual que la aplicación real. Es justo lo que hace
          // que el menú no pase por SessionController.
          ? LearningModuleScreen(
              moduleId: 1,
              userName: 'Sebastián',
              onLogout: _goToLogin,
            )
          : const Scaffold(body: Center(child: Text('ESTOY EN EL LOGIN'))),
    );
  }
}
