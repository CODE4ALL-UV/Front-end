import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';

class _FakeAuth extends AuthStorage {
  _FakeAuth([this.token = 'token-de-prueba']);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

/// La lista de estudiantes del docente: orden, avisos y sacar a alguien.
///
/// El orden por defecto pone arriba a quien no ha empezado y luego a quien
/// peor va, porque es a quien hay que atender; por nombre sirve para buscar a
/// alguien concreto. Sacar a un estudiante le quita el curso, así que se pide
/// confirmación y, si el servidor se niega, el docente tiene que saberlo.
void main() {
  final stats = CourseAnalyticsStore.instance;
  final courses = MyCoursesStore.instance;
  final content = CourseContentStore.instance;
  final theme = AppTheme.getTheme(mode: AppThemeMode.light);
  final messages = theme.extension<MessageTheme>()!;

  setUp(() {
    stats.debugReset();
    courses.debugReset();
    content.debugReset();
  });

  tearDown(() async {
    await courses.select(null);
    stats.debugReset();
    courses.debugReset();
    content.debugReset();
  });

  StudentStats student(
    int id,
    String name, {
    String? email,
    int answered = 0,
    int correct = 0,
    int activities = 0,
  }) => StudentStats(
    userId: id,
    name: name,
    email: email ?? '${name.toLowerCase()}@uv.edu.co',
    answered: answered,
    correct: correct,
    sectionsTouched: activities == 0 ? 0 : 1,
    activitiesDone: activities,
  );

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: TeacherStudentsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Los nombres en el orden en que se ven, de arriba abajo.
  List<String> order(WidgetTester tester, List<String> names) {
    final sorted = [...names]
      ..sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );
    return sorted;
  }

  testWidgets('sin sesión lo dice en vez de enseñar una lista vacía', (
    tester,
  ) async {
    stats.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((_) async => http.Response('{}', 200)),
      auth: _FakeAuth(null),
    );
    await mount(tester);

    expect(
      find.text('Tu sesión no está iniciada. Vuelve a entrar.'),
      findsOneWidget,
    );
    expect(find.textContaining('ningún estudiante'), findsNothing);
  });

  group('volver a pedir la lista', () {
    /// Un servidor que falla con [status] hasta que se le pide que conteste
    /// con [students].
    late int status;
    late List<Map<String, Object>> students;

    void serve() {
      stats.debugUse(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async {
          if (status != 200) return http.Response('fallo', status);
          if (request.url.path.endsWith('/students')) {
            return http.Response(jsonEncode({'students': students}), 200);
          }
          return http.Response(jsonEncode({'total_answers': 0}), 200);
        }),
        auth: _FakeAuth(),
      );
    }

    const ana = {
      'user_id': 3,
      'nombre': 'Ana',
      'correo': 'ana@uv.edu.co',
      'answered': 0,
      'correct': 0,
      'sections_touched': 0,
      'activities_done': 0,
    };

    testWidgets('tras un error se puede volver a intentar', (tester) async {
      status = 500;
      students = [ana];
      serve();
      await mount(tester);

      expect(find.textContaining('El servidor no devolvió'), findsOneWidget);

      status = 200;
      await tester.tap(find.text('Volver a intentarlo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('El servidor no devolvió'), findsNothing);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('sin estudiantes todavía se puede volver a consultar', (
      tester,
    ) async {
      status = 200;
      students = [];
      serve();
      await mount(tester);

      expect(find.textContaining('ningún estudiante'), findsOneWidget);

      // Mientras tanto alguien entró con el código.
      students = [ana];
      await tester.tap(find.text('Volver a consultar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('ningún estudiante'), findsNothing);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('también arrastrando hacia abajo', (tester) async {
      status = 200;
      students = [];
      serve();
      await mount(tester);

      students = [ana];
      await tester.fling(
        find.textContaining('ningún estudiante'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
    });
  });

  testWidgets('primero quien no empezó y quien peor va; luego por nombre', (
    tester,
  ) async {
    stats.debugSeed(
      totalAnswers: 20,
      totalCompletions: 4,
      students: [
        student(1, 'Zoe', answered: 10, correct: 9, activities: 2),
        student(2, 'Ana', answered: 10, correct: 2, activities: 2),
        student(3, 'Beto'),
        student(4, 'Carla', answered: 10, correct: 5, activities: 2),
      ],
    );
    await mount(tester);

    expect(find.text('4 estudiantes · 1 sin empezar'), findsOneWidget);
    expect(order(tester, ['Zoe', 'Ana', 'Beto', 'Carla']), [
      'Beto',
      'Ana',
      'Carla',
      'Zoe',
    ]);

    await tester.tap(find.text('Por dificultad'));
    await tester.pump();

    expect(find.text('Por nombre'), findsOneWidget);
    expect(order(tester, ['Zoe', 'Ana', 'Beto', 'Carla']), [
      'Ana',
      'Beto',
      'Carla',
      'Zoe',
    ]);
  });

  testWidgets('el porcentaje se pinta según cómo va, sin depender del color', (
    tester,
  ) async {
    stats.debugSeed(
      totalAnswers: 30,
      totalCompletions: 6,
      students: [
        student(1, 'Ana', answered: 10, correct: 2, activities: 2),
        student(2, 'Beto', answered: 10, correct: 5, activities: 2),
        student(3, 'Carla', answered: 10, correct: 9, activities: 1),
        // Leyó pero no ha respondido nada todavía.
        student(4, 'Dani', activities: 3),
      ],
    );
    await mount(tester);

    Color colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;

    expect(colorOf('20 %'), messages.dangerForeground);
    expect(colorOf('50 %'), messages.warningForeground);
    expect(colorOf('90 %'), messages.successForeground);
    // Sin respuestas no hay porcentaje que enseñar.
    expect(find.text('3 actividades'), findsOneWidget);
    expect(find.text('1 actividad · 9 aciertos · 1 fallos'), findsOneWidget);
    // Por voz se dice con palabras, sin un «0 %» que asuste.
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'Dani\. 3 actividades terminadas, sin responder preguntas '
          r'todavía\.',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('un estudiante sin nombre se muestra por su correo', (
    tester,
  ) async {
    stats.debugSeed(
      totalAnswers: 0,
      students: [student(1, '', email: 'sin.nombre@uv.edu.co')],
    );
    await mount(tester);

    expect(find.text('sin.nombre@uv.edu.co'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('Sin empezar'), findsOneWidget);
  });

  group('sacar a un estudiante del curso', () {
    late List<http.Request> sent;

    /// Abre el curso 7 del docente y deja a [students] en la lista.
    Future<void> openOwnCourse(
      Future<http.Response?> Function(http.Request request) handler,
      List<StudentStats> students,
    ) async {
      sent = [];
      final client = MockClient((request) async {
        sent.add(request);
        final handled = await handler(request);
        if (handled != null) return handled;
        if (request.url.path == '/api/courses/mine') {
          return http.Response(
            jsonEncode({
              'general_course_id': 1,
              'courses': [
                {
                  'id': 7,
                  'title': 'Python 2026-1',
                  'is_general': false,
                  'is_owner': true,
                  'can_edit': true,
                  'join_code': 'ABC234',
                  'students': students.length,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'version': '', 'count': 0, 'items': <Object>[]}),
          200,
        );
      });
      final api = ApiService(baseUrl: 'http://servidor.de.prueba');
      courses.debugUse(api: api, client: client, auth: _FakeAuth());
      content.debugUse(api: api, client: client, auth: _FakeAuth());
      stats.debugUse(api: api, client: client, auth: _FakeAuth());

      await courses.refresh();
      await courses.select(courses.courses.single);
      stats.debugSeed(totalAnswers: 0, students: students);
    }

    testWidgets('cancelar la confirmación no lo saca', (tester) async {
      await openOwnCourse((_) async => null, [student(5, 'Ana Torres')]);
      await mount(tester);

      await tester.tap(find.byTooltip('Sacar a Ana Torres del curso'));
      await tester.pumpAndSettle();

      expect(
        find.text('¿Sacar a Ana Torres de Python 2026-1?'),
        findsOneWidget,
      );
      expect(find.textContaining('Su avance se guarda'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(sent.where((r) => r.method == 'DELETE'), isEmpty);
      expect(find.text('Ana Torres'), findsOneWidget);
    });

    testWidgets('si el servidor se niega, el docente lee el motivo', (
      tester,
    ) async {
      await openOwnCourse(
        (request) async => request.method == 'DELETE'
            ? http.Response(
                jsonEncode({'detail': 'Ese estudiante ya no está inscrito.'}),
                409,
              )
            : null,
        [student(5, '', email: 'ana@uv.edu.co')],
      );
      await mount(tester);

      // Sin nombre, se le nombra por su correo también al sacarlo.
      await tester.tap(find.byTooltip('Sacar a ana@uv.edu.co del curso'));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Sacar a ana@uv.edu.co de Python 2026-1?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sacar del curso'));
      await tester.pumpAndSettle();

      final delete = sent.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.path, '/api/courses/7/students/5');
      expect(find.text('Ese estudiante ya no está inscrito.'), findsOneWidget);
    });

    testWidgets('al sacarlo se confirma con su nombre', (tester) async {
      await openOwnCourse((request) async {
        if (request.method == 'DELETE') {
          return http.Response('{"removed": true}', 200);
        }
        if (request.url.path == '/api/analytics/summary') {
          return http.Response(
            '{"total_answers": 0, "total_completions": 0}',
            200,
          );
        }
        if (request.url.path == '/api/analytics/students') {
          return http.Response('{"students": []}', 200);
        }
        return null;
      }, [student(5, 'Ana Torres')]);
      await mount(tester);

      await tester.tap(find.byTooltip('Sacar a Ana Torres del curso'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sacar del curso'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ana Torres ya no está en Python 2026-1.'),
        findsOneWidget,
      );
      // Las cifras se vuelven a pedir para ese curso, ya sin ella.
      expect(
        sent.where(
          (r) =>
              r.url.path == '/api/analytics/students' &&
              r.url.queryParameters['course_id'] == '7',
        ),
        isNotEmpty,
      );
      expect(find.textContaining('ningún estudiante'), findsOneWidget);
    });
  });
}
