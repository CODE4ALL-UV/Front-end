import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/courses/teacher_courses_screen.dart';

class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
}

/// Lo que el docente hace con sus cursos desde «Mis cursos».
///
/// Crear, renombrar, copiar o cambiar el código y borrar un curso son
/// acciones que tocan a otras personas: un código cambiado deja fuera a quien
/// no se entere, y un curso borrado se lleva lo editado. Por eso aquí se
/// comprueba qué se envía al servidor, que lo peligroso pide confirmación y
/// que, cuando algo falla, el docente lee por qué en vez de quedarse sin
/// respuesta.
void main() {
  final courses = MyCoursesStore.instance;
  final content = CourseContentStore.instance;
  final analytics = CourseAnalyticsStore.instance;

  late List<http.Request> sent;

  const general = {
    'id': 1,
    'title': 'Curso general de Code4All',
    'is_general': true,
    'teacher': null,
    'can_edit': false,
  };

  const mine = {
    'id': 7,
    'title': 'Python 2026-1',
    'description': 'Grupo de la mañana',
    'is_general': false,
    'teacher': {'id': 30, 'nombre': 'Laura'},
    'is_owner': true,
    'can_edit': true,
    'join_code': 'ABC234',
    'students': 0,
  };

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Un servidor que devuelve [list] en «mis cursos» y deja el resto a
  /// [other]. Lo que no se sabe responder es un temario sin ediciones.
  void serve({
    List<Map<String, Object?>> list = const [mine],
    int? generalId = 1,
    Future<http.Response?> Function(http.Request request)? other,
  }) {
    sent = [];
    final client = MockClient((request) async {
      sent.add(request);
      final handled = await other?.call(request);
      if (handled != null) return handled;
      if (request.url.path == '/api/courses/mine') {
        return json({'general_course_id': generalId, 'courses': list});
      }
      return json({'version': '', 'count': 0, 'items': <Object>[]});
    });
    final api = ApiService(baseUrl: 'http://servidor.de.prueba');
    courses.debugUse(api: api, client: client, auth: _FakeAuth());
    content.debugUse(api: api, client: client, auth: _FakeAuth());
    analytics.debugUse(api: api, client: client, auth: _FakeAuth());
  }

  setUp(() {
    courses.debugReset();
    content.debugReset();
    analytics.debugReset();
  });

  tearDown(() async {
    await courses.select(null);
    courses.debugReset();
    content.debugReset();
    analytics.debugReset();
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await courses.refresh();
    await tester.pumpWidget(
      MaterialApp(
        home: TeacherCoursesScreen(
          courseEditor: (_, course) =>
              Scaffold(body: Text('Editando ${course.title}')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Iterable<http.Request> requests(String method, String path) =>
      sent.where((r) => r.method == method && r.url.path == path);

  group('la lista de cursos', () {
    testWidgets('sin cursos invita a crear el primero', (tester) async {
      serve(list: const []);
      await mount(tester);

      expect(find.text('Mis cursos'), findsOneWidget);
      expect(find.textContaining('Todavía no tienes cursos'), findsOneWidget);
      expect(find.text('Abrir y editar'), findsNothing);
    });

    testWidgets('con estudiantes enseña cuántos y no deja borrarlo', (
      tester,
    ) async {
      serve(
        list: [
          {...mine, 'students': 1},
        ],
      );
      await mount(tester);

      expect(find.text('Grupo de la mañana'), findsOneWidget);
      expect(find.text('1 estudiante'), findsOneWidget);
      expect(find.text('ABC234'), findsOneWidget);
      // Borrarlo dejaría a ese estudiante sin curso.
      expect(find.text('Borrar'), findsNothing);
    });

    testWidgets('abrir un curso lo elige y al volver se vuelve a consultar', (
      tester,
    ) async {
      serve();
      await mount(tester);
      final before = requests('GET', '/api/courses/mine').length;

      await tester.tap(find.text('Abrir y editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editando Python 2026-1'), findsOneWidget);
      expect(courses.active?.id, 7);
      // El temario que se va a editar es el de ese curso, no el general.
      expect(requests('GET', '/api/courses/7/overrides'), isNotEmpty);
      expect(content.courseId, 7);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.text('Mis cursos'), findsOneWidget);
      expect(requests('GET', '/api/courses/mine').length, greaterThan(before));
    });
  });

  group('crear un curso', () {
    testWidgets('sin nombre no envía nada y explica qué falta', (tester) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Crear curso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ponle un nombre al curso, por ejemplo «Python 2026-1».'),
        findsOneWidget,
      );
      expect(requests('POST', '/api/courses'), isEmpty);
    });

    testWidgets('sin curso general no ofrece empezar con lo editado en él', (
      tester,
    ) async {
      serve(generalId: null);
      await mount(tester);

      await tester.tap(find.text('Crear curso'));
      await tester.pumpAndSettle();

      expect(
        find.text('Empezar con lo editado en el curso general'),
        findsNothing,
      );
    });

    testWidgets('cancelar cierra el diálogo sin enviar nada', (tester) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Crear curso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Se arrepiente');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(requests('POST', '/api/courses'), isEmpty);
    });

    testWidgets('si el servidor lo rechaza, el diálogo dice por qué', (
      tester,
    ) async {
      serve(
        other: (request) async => request.method == 'POST'
            ? json({'detail': 'Ya tienes un curso con ese nombre.'}, 409)
            : null,
      );
      await mount(tester);

      await tester.tap(find.text('Crear curso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Python 2026-1');
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Ya tienes un curso con ese nombre.'), findsOneWidget);
      // Sigue abierto para corregir el nombre sin volver a escribir todo.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Crear'), findsOneWidget);
    });

    testWidgets('al crearlo se anuncia con su código para compartirlo', (
      tester,
    ) async {
      serve(
        other: (request) async => request.method == 'POST'
            ? json({
                ...mine,
                'id': 9,
                'title': 'Python nocturno',
                'join_code': 'XYZ789',
              }, 201)
            : null,
      );
      await mount(tester);

      await tester.tap(find.text('Crear curso'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).at(0),
        '  Python nocturno ',
      );
      await tester.enterText(find.byType(TextField).at(1), ' Martes y jueves ');
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      final created = requests('POST', '/api/courses').single;
      // Sin marcar la casilla empieza con el temario original.
      expect(jsonDecode(created.body), {
        'title': 'Python nocturno',
        'description': 'Martes y jueves',
      });
      expect(
        find.text('Curso Python nocturno creado. Su código es XYZ789.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('renombrar', () {
    Future<void> openRename(WidgetTester tester) async {
      await tester.tap(find.text('Renombrar'));
      await tester.pumpAndSettle();
      expect(find.text('Renombrar curso'), findsOneWidget);
    }

    testWidgets('un nombre vacío no se envía', (tester) async {
      serve();
      await mount(tester);
      await openRename(tester);

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El curso necesita un nombre.'), findsOneWidget);
      expect(sent.where((r) => r.method == 'PATCH'), isEmpty);
    });

    testWidgets('sin servidor, el error se ve dentro del diálogo', (
      tester,
    ) async {
      serve(
        other: (request) async => request.method == 'PATCH'
            ? throw http.ClientException('sin red')
            : null,
      );
      await mount(tester);
      await openRename(tester);

      await tester.enterText(find.byType(TextField).first, 'Python 2026-2');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El servidor no responde. Vuelve a intentarlo en un momento.',
        ),
        findsOneWidget,
      );
      expect(find.text('Renombrar curso'), findsOneWidget);
    });

    testWidgets('al renombrarlo se anuncia el nombre nuevo', (tester) async {
      serve(
        other: (request) async => request.method == 'PATCH'
            ? json({...mine, 'title': 'Python 2026-2'})
            : null,
      );
      await mount(tester);
      await openRename(tester);

      await tester.enterText(find.byType(TextField).first, 'Python 2026-2');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('El curso ahora se llama Python 2026-2.'),
        findsOneWidget,
      );
    });
  });

  group('el código de inscripción', () {
    late List<String> copied;

    void captureClipboard(WidgetTester tester) {
      copied = [];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
    }

    testWidgets('copiar el código lo deja en el portapapeles', (tester) async {
      serve();
      await mount(tester);
      captureClipboard(tester);

      await tester.tap(find.text('Copiar código'));
      await tester.pumpAndSettle();

      expect(copied, ['ABC234']);
      expect(find.text('Código ABC234 copiado.'), findsOneWidget);
    });

    testWidgets('sin código no se copia nada', (tester) async {
      serve(
        list: [
          {...mine, 'join_code': null},
        ],
      );
      await mount(tester);
      captureClipboard(tester);

      await tester.tap(find.text('Copiar código'));
      await tester.pumpAndSettle();

      expect(copied, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('cambiar el código pide confirmación y cancelar no lo cambia', (
      tester,
    ) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Nuevo código'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cambiar el código de Python 2026-1?'), findsOneWidget);
      expect(
        find.textContaining('El código actual dejará de servir'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(requests('POST', '/api/courses/7/join-code'), isEmpty);
    });

    testWidgets('al confirmar se pide un código nuevo y se anuncia', (
      tester,
    ) async {
      serve(
        other: (request) async => request.url.path == '/api/courses/7/join-code'
            ? json({...mine, 'join_code': 'NEW567'})
            : null,
      );
      await mount(tester);

      await tester.tap(find.text('Nuevo código'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar código'));
      await tester.pumpAndSettle();

      expect(requests('POST', '/api/courses/7/join-code'), hasLength(1));
      expect(find.text('Nuevo código: NEW567.'), findsOneWidget);
    });

    testWidgets('si no se puede cambiar, el docente lee el motivo', (
      tester,
    ) async {
      serve(
        other: (request) async => request.url.path == '/api/courses/7/join-code'
            ? http.Response('fallo', 500)
            : null,
      );
      await mount(tester);

      await tester.tap(find.text('Nuevo código'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cambiar código'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo completar (error 500).'), findsOneWidget);
    });
  });

  group('borrar un curso', () {
    testWidgets('pide confirmación y, al aceptar, lo borra', (tester) async {
      var deleted = false;
      serve(
        other: (request) async {
          if (request.method == 'DELETE') {
            deleted = true;
            return json({'deleted': true});
          }
          if (deleted && request.url.path == '/api/courses/mine') {
            return json({
              'general_course_id': 1,
              'courses': [general],
            });
          }
          return null;
        },
      );
      await mount(tester);

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar Python 2026-1?'), findsOneWidget);
      expect(
        find.text('Se borran también las secciones que editaste en él.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Borrar curso'));
      await tester.pumpAndSettle();

      expect(requests('DELETE', '/api/courses/7'), hasLength(1));
      expect(find.text('Curso Python 2026-1 borrado.'), findsOneWidget);
      // La lista se rehace sola con lo que queda.
      expect(find.text('Python 2026-1'), findsNothing);
      expect(find.text('Curso general de Code4All'), findsOneWidget);
    });

    testWidgets('cancelar no borra nada', (tester) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(sent.where((r) => r.method == 'DELETE'), isEmpty);
      expect(find.text('Python 2026-1'), findsOneWidget);
    });

    testWidgets('si el servidor se niega, se dice por qué', (tester) async {
      serve(
        other: (request) async => request.method == 'DELETE'
            ? json({'detail': 'El curso ya tiene estudiantes.'}, 409)
            : null,
      );
      await mount(tester);

      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar curso'));
      await tester.pumpAndSettle();

      expect(find.text('El curso ya tiene estudiantes.'), findsOneWidget);
      expect(find.text('Python 2026-1'), findsOneWidget);
    });
  });
}
