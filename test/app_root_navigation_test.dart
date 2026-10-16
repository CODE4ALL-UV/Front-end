import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/app.dart';
import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/data/services/launch_link.dart';
import 'package:flutter_code4all/data/services/session_controller.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/courses/student_courses_screen.dart';
import 'package:flutter_code4all/ui/courses/teacher_courses_screen.dart';
import 'package:flutter_code4all/ui/director/director_home_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/form_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/reset_password_screen.dart';
import 'package:flutter_code4all/utils/browser_port_stub.dart';

/// Respuesta JSON en UTF-8, como la manda el servidor.
http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Un servidor de mentira que contesta lo justo para entrar con cada rol.
class _FakeServer {
  String role = 'estudiante';
  String name = 'Ana';
  int loginStatus = 200;

  /// Los cursos de quien entra. Nulo: el servidor de antes, sin cursos.
  List<Map<String, dynamic>>? courses;

  final List<http.Request> requests = [];

  Iterable<http.Request> to(String path) =>
      requests.where((r) => r.url.path == path);

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    switch (request.url.path) {
      case '/api/auth/login':
        if (loginStatus != 200) {
          return _json({
            'detail': 'Correo o contraseña incorrectos.',
          }, loginStatus);
        }
        return _json({
          'access_token': 'token-de-prueba',
          'token_type': 'bearer',
          'user_id': 7,
          'email': 'ana@example.com',
          'nombre': name,
          'rol': role,
        }, 200);
      case '/api/auth/register':
        return _json({
          'id_usuario': 8,
          'nombre': 'Ana',
          'correo': 'ana@example.com',
          'rol': 'estudiante',
          'fecha_registro': '2026-10-15T10:00:00Z',
        }, 201);
      case '/api/auth/password/reset':
        return _json({
          'detail': 'Listo. Ya puedes iniciar sesión con tu contraseña nueva.',
        }, 200);
      case '/api/courses/mine':
        final list = courses;
        if (list == null) return _json({'detail': 'Not Found'}, 404);
        return _json({'courses': list, 'general_course_id': 1}, 200);
      case '/api/oversight/teachers':
        return _json({'teachers': []}, 200);
      case '/api/oversight/content':
        return _json({'items': []}, 200);
      case '/api/analytics/completions':
        return _json({'ok': true}, 201);
    }
    return _json({'detail': 'Not Found'}, 404);
  }
}

/// El servidor de la prueba en curso. Los almacenes son únicos para toda la
/// aplicación y se quedan con el primer cliente que se les da: por eso todos
/// los clientes de mentira le preguntan a este, sea cual sea la prueba que
/// los creó.
late _FakeServer _server;

http.Client _client() => MockClient((request) => _server.handle(request));

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
  description: 'TextField con etiqueta "$label"',
);

/// La raíz de la aplicación: `main()` arranca [App] y todo lo demás cuelga
/// de ella.
///
/// Aquí se comprueba lo que solo hace la raíz: que se empieza en el login,
/// que cada rol llega a su pantalla, que cerrar sesión desde cualquier sitio
/// devuelve al login sin dejar los cursos del anterior, que el enlace del
/// correo abre el cambio de contraseña y que los colores y el tamaño del
/// texto se aplican a toda la aplicación.
void main() {
  const ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    // El aviso del atajo Braille se dice en voz alta al abrir el login.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async => 1);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  void useFakeServer() {
    final api = ApiService(baseUrl: 'http://servidor.de.prueba');
    MyCoursesStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client(), auth: AuthStorage());
    DirectorOversightStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client(), auth: AuthStorage());
    CourseAnalyticsStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client(), auth: AuthStorage());
    CourseContentStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client(), auth: AuthStorage());
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    LaunchLink.debugReset();
    SessionController.instance.debugReset();
    ThemeManager.changeTheme(AppThemeMode.light);
    _server = _FakeServer();
    useFakeServer();
  });

  tearDown(() {
    SessionController.instance.debugReset();
    LaunchLink.debugReset();
    MyCoursesStore.instance.debugReset();
    DirectorOversightStore.instance.debugReset();
    CourseAnalyticsStore.instance.debugReset();
    CourseContentStore.instance.debugReset();
    CourseProgressStore.instance.reportCompletionsTo(null);
    AccessibilityTextScaleController.global.setScale(1.0);
    ThemeManager.changeTheme(AppThemeMode.light);
    accessibilityReadingState.clearHighlight();
    accessibilityReadingState.currentText.value = null;
  });

  /// Todo lo que pida `http.Client()` dentro de la prueba —el login, el
  /// registro, el cambio de contraseña— llega al servidor de mentira.
  Future<void> withServer(Future<void> Function() body) =>
      http.runWithClient(body, _client);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> pumpApp(WidgetTester tester, {Widget app = const App()}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await settle(tester);
  }

  /// Desmonta la aplicación para que no queden temporizadores vivos.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(_field('Correo electrónico'), 'ana@example.com');
    await tester.enterText(_field('Contraseña'), 'clave-de-prueba');
    final button = find.text('INICIAR SESIÓN');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settle(tester);
  }

  group('arranque', () {
    testWidgets('empieza en el login, sin el botón de colores', (tester) async {
      await withServer(() async {
        await pumpApp(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.bySemanticsLabel('Cambiar tema'), findsNothing);
        // Desde el arranque cualquier pantalla puede cerrar sesión.
        expect(SessionController.instance.canLogout, isTrue);
        // La app es en español también en lo que dibuja Flutter.
        final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(material.locale, const Locale('es'));
        expect(material.title, 'Code4All');

        await unmount(tester);
      });
    });

    testWidgets('el enlace del correo abre el cambio de contraseña', (
      tester,
    ) async {
      LaunchLink.capture(
        MemoryBrowserPort(
          Uri.parse('https://code4all.test/?restablecer=token-del-correo'),
        ),
      );

      await withServer(() async {
        await pumpApp(tester);

        expect(find.byType(ResetPasswordScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(
          tester
              .widget<ResetPasswordScreen>(find.byType(ResetPasswordScreen))
              .token,
          'token-del-correo',
        );

        await tester.enterText(
          find.byKey(const ValueKey('reset-password')),
          'clave-nueva',
        );
        await tester.enterText(
          find.byKey(const ValueKey('reset-repeat')),
          'clave-nueva',
        );
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await settle(tester);

        final reset = _server.to('/api/auth/password/reset').single;
        expect(jsonDecode(reset.body), {
          'token': 'token-del-correo',
          'password': 'clave-nueva',
        });

        await tester.tap(find.text('IR A INICIAR SESIÓN'));
        await settle(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(ResetPasswordScreen), findsNothing);
        await unmount(tester);
      });
    });
  });

  group('cada rol llega a su pantalla', () {
    testWidgets('el estudiante elige curso si el servidor tiene cursos', (
      tester,
    ) async {
      _server.courses = [
        {'id': 1, 'title': 'Curso general', 'is_general': true},
        {
          'id': 5,
          'title': 'Python de la tarde',
          'teacher': {'id': 3, 'nombre': 'Laura'},
        },
      ];

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        final login = _server.to('/api/auth/login').single;
        expect(jsonDecode(login.body), {
          'email': 'ana@example.com',
          'password': 'clave-de-prueba',
        });

        expect(find.byType(StudentCoursesScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.textContaining('Python de la tarde'), findsWidgets);
        // El nombre guardado al entrar es el que se muestra.
        expect(
          tester
              .widget<StudentCoursesScreen>(find.byType(StudentCoursesScreen))
              .userName,
          'Ana',
        );
        expect(MyCoursesStore.instance.supported, isTrue);
        await unmount(tester);
      });
    });

    testWidgets('con el servidor de antes entra directo a los módulos', (
      tester,
    ) async {
      _server.courses = null;

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(find.byType(LearningModuleScreen), findsWidgets);
        expect(find.byType(StudentCoursesScreen), findsNothing);
        expect(MyCoursesStore.instance.supported, isFalse);
        await unmount(tester);
      });
    });

    testWidgets('el docente ve sus cursos y abre el editor de uno', (
      tester,
    ) async {
      // El rol llega con mayúscula: la app no debe depender de cómo lo
      // escriba el servidor.
      _server
        ..role = 'Docente'
        ..name = 'Laura'
        ..courses = [
          {
            'id': 5,
            'title': 'Python de la tarde',
            'is_owner': true,
            'can_edit': true,
            'join_code': 'ABC123',
            'students': 4,
          },
        ];

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(find.byType(TeacherCoursesScreen), findsOneWidget);
        expect(find.textContaining('Python de la tarde'), findsWidgets);

        final open = find.text('Abrir y editar');
        await tester.ensureVisible(open);
        await tester.tap(open);
        await settle(tester);

        final editor = tester.widget<TeacherCourseScreen>(
          find.byType(TeacherCourseScreen),
        );
        expect(editor.course?.id, 5);
        expect(editor.userName, 'Laura');
        await unmount(tester);
      });
    });

    testWidgets('el docente con el servidor de antes edita el curso único', (
      tester,
    ) async {
      _server
        ..role = 'docente'
        ..courses = null;

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(find.byType(TeacherCourseScreen), findsOneWidget);
        expect(find.byType(TeacherCoursesScreen), findsNothing);
        expect(
          tester
              .widget<TeacherCourseScreen>(find.byType(TeacherCourseScreen))
              .course,
          isNull,
        );
        await unmount(tester);
      });
    });

    testWidgets('la dirección entra a su panel', (tester) async {
      _server
        ..role = 'director'
        ..name = 'Marta';

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        final home = tester.widget<DirectorHomeScreen>(
          find.byType(DirectorHomeScreen),
        );
        expect(home.userName, 'Marta');
        // Su panel pide el seguimiento de los docentes con la sesión nueva.
        final teachers = _server.to('/api/oversight/teachers').first;
        expect(teachers.headers['Authorization'], 'Bearer token-de-prueba');
        await unmount(tester);
      });
    });

    testWidgets('un nombre vacío se muestra como «Usuario»', (tester) async {
      _server
        ..role = 'director'
        ..name = '   ';

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(
          tester
              .widget<DirectorHomeScreen>(find.byType(DirectorHomeScreen))
              .userName,
          'Usuario',
        );
        await unmount(tester);
      });
    });

    testWidgets('un rol que la app no conoce se queda en el login', (
      tester,
    ) async {
      _server.role = 'invitado';

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(DirectorHomeScreen), findsNothing);
        expect(find.byType(TeacherCourseScreen), findsNothing);
        expect(find.byType(StudentCoursesScreen), findsNothing);
        await unmount(tester);
      });
    });

    testWidgets('con la contraseña mal se queda en el login y lo dice', (
      tester,
    ) async {
      _server.loginStatus = 401;

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
        await unmount(tester);
      });
    });
  });

  group('cerrar sesión', () {
    testWidgets('desde cualquier sitio vuelve al login y olvida los cursos', (
      tester,
    ) async {
      _server.courses = [
        {'id': 1, 'title': 'Curso general', 'is_general': true},
      ];

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);
        expect(find.byType(StudentCoursesScreen), findsOneWidget);
        expect(MyCoursesStore.instance.courses, isNotEmpty);

        expect(SessionController.instance.logout(), isTrue);
        await settle(tester);

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(StudentCoursesScreen), findsNothing);
        // El siguiente que entre no hereda los cursos de nadie.
        expect(MyCoursesStore.instance.courses, isEmpty);
        expect(MyCoursesStore.instance.supported, isNull);
        await unmount(tester);
      });
    });
  });

  group('registro', () {
    testWidgets('muestra «Cambiar tema» y al registrarse vuelve al login', (
      tester,
    ) async {
      await withServer(() async {
        await pumpApp(tester);

        final register = find.text('REGISTRARSE');
        await tester.ensureVisible(register);
        await tester.tap(register);
        await settle(tester);

        expect(find.byType(FormScreen), findsOneWidget);
        expect(find.bySemanticsLabel('Cambiar tema'), findsOneWidget);

        final fields = find.descendant(
          of: find.byType(FormScreen),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), 'Ana');
        await tester.enterText(fields.at(1), 'ana@example.com');
        await tester.enterText(fields.at(2), 'clave-de-prueba');
        final terms = find.text('Acepto términos y condiciones');
        await tester.ensureVisible(terms);
        await tester.tap(terms);
        await tester.pump();
        final submit = find.text('Registrarse');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await settle(tester);

        expect(_server.to('/api/auth/register'), hasLength(1));
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(FormScreen), findsNothing);
        expect(find.bySemanticsLabel('Cambiar tema'), findsNothing);
        await unmount(tester);
      });
    });

    testWidgets('el selector de colores aplica el tema elegido', (
      tester,
    ) async {
      // Arrancada tal cual, como en main(): sin un MaterialApp encima. La
      // hoja se abría con el contexto de la raíz, que está por encima del
      // MaterialApp de la app, y pulsar el botón lanzaba «No
      // MaterialLocalizations found» sin abrir nada.
      await withServer(() async {
        await pumpApp(tester);

        final register = find.text('REGISTRARSE');
        await tester.ensureVisible(register);
        await tester.tap(register);
        await settle(tester);

        ThemeData appTheme() =>
            tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;

        const options = {
          'Oscuro': AppThemeMode.dark,
          'Deuteranopía (Ausencia de percepción del verde)':
              AppThemeMode.deuteranopia,
          'Deuteranomalía (Sensibilidad reducida al verde)':
              AppThemeMode.deuteranomalia,
          'Protanopía (Ausencia de percepción del rojo)':
              AppThemeMode.protanopia,
          'Protanomalía (Sensibilidad reducida al rojo)':
              AppThemeMode.protanomalia,
          'Tritanopía (Ausencia de percepción del azul)':
              AppThemeMode.tritanopia,
          'Tritanomalía (Sensibilidad reducida al azul)':
              AppThemeMode.tritanomalia,
          'Acromatopsia (Monocromático)': AppThemeMode.achromatopsia,
          'Claro': AppThemeMode.light,
        };

        for (final MapEntry(key: label, value: mode) in options.entries) {
          await tester.tap(find.bySemanticsLabel('Cambiar tema'));
          await settle(tester);
          final option = find.text(label);
          await tester.ensureVisible(option);
          await tester.tap(option);
          await settle(tester);

          expect(ThemeManager.themeNotifier.value, mode, reason: label);
          expect(
            appTheme(),
            same(AppTheme.getTheme(mode: mode)),
            reason: 'la app entera cambia a $label',
          );
        }

        // Elegir el tema que ya está puesto no cambia nada.
        await tester.tap(find.bySemanticsLabel('Cambiar tema'));
        await settle(tester);
        await tester.tap(find.text('Claro'));
        await settle(tester);
        expect(ThemeManager.themeNotifier.value, AppThemeMode.light);

        // Cerrar la hoja sin elegir tampoco.
        await tester.tap(find.bySemanticsLabel('Cambiar tema'));
        await settle(tester);
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);
        expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
        await unmount(tester);
      });
    });
  });

  group('ajustes que valen para toda la app', () {
    testWidgets('agrandar la letra en el login agranda toda la app', (
      tester,
    ) async {
      await withServer(() async {
        await pumpApp(tester);

        double scaleOf(Type screen) => MediaQuery.of(
          tester.element(find.byType(screen)),
        ).textScaler.scale(10);

        expect(scaleOf(LoginScreen), closeTo(10, 0.001));

        await tester.tap(find.byTooltip('Aumentar el tamaño del texto'));
        await settle(tester);

        expect(
          AccessibilityTextScaleController.global.scale,
          closeTo(1.1, 1e-9),
        );
        expect(scaleOf(LoginScreen), closeTo(11, 0.001));
        await unmount(tester);
      });
    });

    testWidgets('los colores elegidos por la dirección cambian toda la app', (
      tester,
    ) async {
      _server.role = 'director';

      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);
        expect(find.byType(DirectorHomeScreen), findsOneWidget);

        await tester.tap(
          find.byTooltip('Accesibilidad: colores y tamaño del texto'),
        );
        await settle(tester);
        await tester.tap(find.text('Oscuro'));
        await settle(tester);

        expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
          same(AppTheme.getTheme(mode: AppThemeMode.dark)),
        );
        await unmount(tester);
      });
    });

    testWidgets('cada actividad terminada se anota en las estadísticas', (
      tester,
    ) async {
      await withServer(() async {
        await pumpApp(tester);
        await signIn(tester);

        await CourseProgressStore.instance.markCompleted(
          'prueba-app-raiz',
          CourseActivityKind.lectura,
        );
        await settle(tester);

        final completion = _server.to('/api/analytics/completions').single;
        expect(
          jsonDecode(completion.body),
          containsPair('section_id', 'prueba-app-raiz'),
        );
        expect(completion.headers['Authorization'], 'Bearer token-de-prueba');

        await CourseProgressStore.instance.resetSection('prueba-app-raiz', [
          CourseActivityKind.lectura,
        ]);
        await unmount(tester);
      });
    });
  });
}
