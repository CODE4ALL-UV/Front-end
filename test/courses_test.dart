import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/ui/courses/courses_gate.dart';
import 'package:flutter_code4all/ui/courses/student_courses_screen.dart';
import 'package:flutter_code4all/ui/courses/teacher_courses_screen.dart';
import 'package:flutter_code4all/ui/director/director_home_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';

/// Cada docente con sus cursos y cada estudiante en los de sus docentes.
///
/// Lo que se comprueba aquí es lo que se ve y lo que viaja: que al abrir un
/// curso la aplicación pida *sus* ediciones y no las de otro, que el código
/// de inscripción esté a mano del docente, y que con el servidor de antes
/// todo siga como siempre.
class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
}

const _general = {
  'id': 1,
  'title': 'Curso general de Code4All',
  'is_general': true,
  'teacher': null,
  'can_edit': false,
};

const _teacherCourse = {
  'id': 7,
  'title': 'Python 2026-1',
  'description': 'Grupo de la mañana',
  'is_general': false,
  'teacher': {'id': 30, 'nombre': 'Laura'},
  'is_owner': false,
  'can_edit': false,
};

void main() {
  final courses = MyCoursesStore.instance;
  final content = CourseContentStore.instance;
  final api = ApiService(baseUrl: 'http://servidor.de.prueba');

  late List<http.Request> sent;

  void serve(Future<http.Response> Function(http.Request request) handler) {
    sent = [];
    final client = MockClient((request) {
      sent.add(request);
      return handler(request);
    });
    courses.debugUse(api: api, client: client, auth: _FakeAuth());
    content.debugUse(api: api, client: client, auth: _FakeAuth());
    CourseAnalyticsStore.instance.debugUse(
      api: api,
      client: client,
      auth: _FakeAuth(),
    );
    DirectorOversightStore.instance.debugUse(
      api: api,
      client: client,
      auth: _FakeAuth(),
    );
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  final noEdits = {'version': '', 'count': 0, 'items': <Object>[]};

  setUp(() {
    courses.debugReset();
    content.debugReset();
    CourseAnalyticsStore.instance.debugReset();
    DirectorOversightStore.instance.debugReset();
  });

  tearDown(() async {
    await courses.select(null);
    courses.debugReset();
    content.debugReset();
    CourseAnalyticsStore.instance.debugReset();
    DirectorOversightStore.instance.debugReset();
  });

  testWidgets(
    'con el servidor de antes se entra como siempre, sin elegir curso',
    (tester) async {
      serve((_) async => http.Response('Not Found', 404));

      await tester.pumpWidget(
        MaterialApp(
          home: CoursesGate(
            withCourses: (_) => const Text('mis cursos'),
            withoutCourses: (_) => const Text('curso único'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('curso único'), findsOneWidget);
      expect(courses.supported, isFalse);
    },
  );

  testWidgets('el estudiante entra al curso de su docente y ve sus ediciones', (
    tester,
  ) async {
    serve((request) async {
      if (request.url.path == '/api/courses/mine') {
        return json({
          'general_course_id': 1,
          'courses': [_general, _teacherCourse],
        });
      }
      if (request.url.path == '/api/courses/7/overrides') {
        return json({
          'version': 'v1',
          'count': 1,
          'items': [
            {
              'scope': 'module',
              'target_id': '1',
              'content': {'title': 'Primeros pasos, según Laura'},
            },
          ],
        });
      }
      return json(noEdits);
    });

    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CoursesGate(
          withoutCourses: (_) => const Text('curso único'),
          withCourses: (_) => StudentCoursesScreen(
            courseHome: (_) => const Scaffold(body: Text('ruta de módulos')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Curso general de Code4All'), findsOneWidget);
    expect(find.text('Python 2026-1'), findsOneWidget);
    expect(find.text('Docente: Laura'), findsOneWidget);

    await tester.tap(find.text('Python 2026-1'));
    await tester.pumpAndSettle();

    expect(find.text('ruta de módulos'), findsOneWidget);
    final asked = sent.where((r) => r.url.path == '/api/courses/7/overrides');
    expect(asked, isNotEmpty);
    expect(asked.first.headers['Authorization'], 'Bearer token-de-prueba');

    // Todo el resto de la aplicación habla ya de ese curso.
    final module = PythonCourseCatalog.modules.first;
    expect(content.moduleTitle(1, module.title), 'Primeros pasos, según Laura');
    expect(CourseProgressStore.instance.courseId, 7);
    expect(CourseAnalyticsStore.instance.courseId, 7);
  });

  testWidgets('un código equivocado dice por qué no entra', (tester) async {
    serve((request) async {
      if (request.url.path == '/api/courses/join') {
        return json({
          'detail':
              'Ese código no es de ningún curso. Revisa que esté bien escrito.',
        }, 404);
      }
      return json({
        'general_course_id': 1,
        'courses': [_general],
      });
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CoursesGate(
          withoutCourses: (_) => const Text('curso único'),
          withCourses: (_) =>
              StudentCoursesScreen(courseHome: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unirme a un curso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz999');
    await tester.tap(find.text('Unirme'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ese código no es de ningún curso. Revisa que esté bien escrito.',
      ),
      findsOneWidget,
    );
    final join = sent.singleWhere((r) => r.url.path == '/api/courses/join');
    expect(jsonDecode(join.body)['code'], 'zzz999');
  });

  testWidgets('el docente tiene el código a mano y crea cursos nuevos', (
    tester,
  ) async {
    final mine = {
      ..._teacherCourse,
      'is_owner': true,
      'can_edit': true,
      'join_code': 'ABC234',
      'students': 0,
    };
    serve((request) async {
      if (request.url.path == '/api/courses' && request.method == 'POST') {
        return json({...mine, 'id': 8, 'title': 'Python nocturno'}, 201);
      }
      return json({
        'general_course_id': 1,
        'courses': [mine],
      });
    });

    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CoursesGate(
          withoutCourses: (_) => const Text('curso único'),
          withCourses: (_) =>
              TeacherCoursesScreen(courseEditor: (_, _) => const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABC234'), findsOneWidget);
    expect(find.text('0 estudiantes'), findsOneWidget);
    // Sin estudiantes todavía se puede borrar, por si se creó por error.
    expect(find.text('Borrar'), findsOneWidget);

    await tester.tap(find.text('Crear curso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Python nocturno');
    await tester.tap(find.text('Empezar con lo editado en el curso general'));
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    final created = sent.singleWhere(
      (r) => r.url.path == '/api/courses' && r.method == 'POST',
    );
    expect(jsonDecode(created.body), {
      'title': 'Python nocturno',
      'description': '',
      'copy_from': 1,
    });
  });

  test(
    'lo que edita el docente se guarda en su curso, no en el de todos',
    () async {
      serve((_) async => json(noEdits));

      await content.useCourse(7);
      final section = PythonCourseCatalog.modules.first.sections.first;
      await content.saveSection(section);

      final saved = sent.singleWhere((r) => r.method == 'PUT');
      expect(saved.url.path, '/api/courses/7/overrides/section/${section.id}');
    },
  );

  test(
    'sin curso se usa el camino de siempre, que entiende cualquier servidor',
    () async {
      serve((_) async => json(noEdits));

      await content.useCourse(null);
      await content.refresh();

      expect(sent.last.url.path, '/api/course/overrides');
    },
  );

  final ownCourse = {
    ..._teacherCourse,
    'is_owner': true,
    'can_edit': true,
    'join_code': 'ABC234',
    'students': 1,
  };

  testWidgets('el docente renombra su curso', (tester) async {
    serve((request) async {
      if (request.method == 'PATCH') {
        return json({...ownCourse, 'title': 'Python 2026-2'});
      }
      return json({
        'general_course_id': 1,
        'courses': [ownCourse],
      });
    });

    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CoursesGate(
          withoutCourses: (_) => const Text('curso único'),
          withCourses: (_) =>
              TeacherCoursesScreen(courseEditor: (_, _) => const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renombrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Python 2026-2');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final patch = sent.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.path, '/api/courses/7');
    expect(jsonDecode(patch.body), {
      'title': 'Python 2026-2',
      'description': 'Grupo de la mañana',
    });
  });

  testWidgets('el docente saca a un estudiante de su curso', (tester) async {
    serve((request) async {
      final path = request.url.path;
      if (path == '/api/courses/mine') {
        return json({
          'general_course_id': 1,
          'courses': [ownCourse],
        });
      }
      if (path == '/api/analytics/students') {
        return json({
          'students': [
            {
              'user_id': 5,
              'nombre': 'Ana Torres',
              'correo': 'ana@x.co',
              'answered': 0,
              'correct': 0,
              'sections_touched': 0,
              'activities_done': 0,
            },
          ],
        });
      }
      if (path == '/api/analytics/summary') {
        return json({'total_answers': 0, 'total_completions': 0});
      }
      if (request.method == 'DELETE') return json({'removed': true});
      return json(noEdits);
    });

    await courses.refresh();
    await courses.select(courses.courses.single);
    await CourseAnalyticsStore.instance.refresh();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TeacherStudentsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sacar a Ana Torres del curso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sacar del curso'));
    await tester.pumpAndSettle();

    final removed = sent.singleWhere((r) => r.method == 'DELETE');
    expect(removed.url.path, '/api/courses/7/students/5');
    // Las cifras se piden otra vez, ya sin ese estudiante.
    expect(
      sent.where((r) => r.url.path == '/api/analytics/students').length,
      greaterThanOrEqualTo(2),
    );
  });

  testWidgets('en el curso general no se saca a nadie', (tester) async {
    serve((request) async {
      if (request.url.path == '/api/courses/mine') {
        return json({
          'general_course_id': 1,
          'courses': [_general],
        });
      }
      if (request.url.path == '/api/analytics/students') {
        return json({
          'students': [
            {'user_id': 5, 'nombre': 'Ana Torres', 'correo': 'ana@x.co'},
          ],
        });
      }
      return json({'total_answers': 0, 'total_completions': 0});
    });

    await courses.refresh();
    await courses.select(courses.courses.single);
    await CourseAnalyticsStore.instance.refresh();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TeacherStudentsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.byTooltip('Sacar a Ana Torres del curso'), findsNothing);
  });

  testWidgets('la coordinación filtra las estadísticas por curso', (
    tester,
  ) async {
    serve((request) async {
      final path = request.url.path;
      if (path == '/api/courses/mine') {
        return json({
          'general_course_id': 1,
          'courses': [_general, _teacherCourse],
        });
      }
      if (path == '/api/analytics/summary') {
        return json({'total_answers': 0, 'total_completions': 0});
      }
      if (path == '/api/analytics/students') return json({'students': []});
      if (path.startsWith('/api/oversight/')) {
        return json({'teachers': [], 'items': [], 'courses': []});
      }
      return json(noEdits);
    });

    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: DirectorHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Todos los cursos'), findsOneWidget);

    await tester.tap(find.text('Todos los cursos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python 2026-1 · Laura').last);
    await tester.pumpAndSettle();

    expect(CourseAnalyticsStore.instance.courseId, 7);
    final filtered = sent.where(
      (r) =>
          r.url.path == '/api/analytics/summary' &&
          r.url.queryParameters['course_id'] == '7',
    );
    expect(filtered, isNotEmpty);
  });
}
