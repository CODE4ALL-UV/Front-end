import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/teacher/teacher_report.dart';
import 'package:flutter_code4all/ui/teacher/teacher_stats_screen.dart';

class _FakeAuth extends AuthStorage {
  _FakeAuth([this.token = 'token-de-prueba']);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

/// Las estadísticas del docente cuando el servidor falla, mientras cargan y
/// cuando hay datos a medias, y el informe que se copia para pegarlo fuera.
///
/// Un panel de cifras que se queda en blanco sin decir por qué, o que pinta
/// en verde lo que va mal, lleva al docente a conclusiones equivocadas. Y el
/// informe tiene que poder copiarse entero: es lo que acaba en un correo o en
/// el capítulo de resultados de una tesis.
void main() {
  final stats = CourseAnalyticsStore.instance;
  final theme = AppTheme.getTheme(mode: AppThemeMode.light);
  final messages = theme.extension<MessageTheme>()!;

  setUp(stats.debugReset);
  tearDown(stats.debugReset);

  late List<http.Request> sent;

  void serve(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'token-de-prueba',
  }) {
    sent = [];
    stats.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
      auth: _FakeAuth(token),
    );
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Lo que devolvería un servidor con algo de actividad.
  Future<http.Response> withData(http.Request request) async {
    if (request.url.path == '/api/analytics/summary') {
      return json({
        'total_answers': 40,
        'total_completions': 14,
        'sections': [
          {'section_id': 'm1-s1', 'answered': 40, 'correct': 20, 'students': 2},
        ],
        'questions': <Object>[],
        'completions': [
          {'section_id': 'm1-s1', 'activity': 'lectura', 'students': 9},
          {'section_id': 'm1-s1', 'activity': 'quiz', 'students': 5},
        ],
      });
    }
    return json({
      'students': [
        {
          'user_id': 1,
          'nombre': 'Ana',
          'correo': 'ana@uv.edu.co',
          'answered': 40,
          'correct': 20,
          'sections_touched': 1,
          'activities_done': 14,
        },
      ],
    });
  }

  Future<void> mount(WidgetTester tester, {double height = 2600}) async {
    tester.view.physicalSize = Size(600, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: TeacherStatsScreen()),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('cuando el servidor no da los datos', () {
    testWidgets('sin sesión lo dice y no pregunta al servidor', (tester) async {
      serve(withData, token: null);
      await mount(tester);
      await settle(tester);

      expect(sent, isEmpty);
      expect(
        find.text('Tu sesión no está iniciada. Vuelve a entrar.'),
        findsOneWidget,
      );
      expect(find.text('Volver a intentarlo'), findsOneWidget);
    });

    testWidgets('sin permiso lo explica en vez de enseñar ceros', (
      tester,
    ) async {
      serve((_) async => json({'detail': 'no'}, 403));
      await mount(tester);
      await settle(tester);

      expect(
        find.text('Tu cuenta no tiene permiso para ver estos datos.'),
        findsOneWidget,
      );
      expect(find.text('Actividades hechas'), findsNothing);
    });

    testWidgets('«Volver a intentarlo» pide otra vez y enseña las cifras', (
      tester,
    ) async {
      var fail = true;
      serve((request) async {
        if (fail) return http.Response('caído', 502);
        return withData(request);
      });
      await mount(tester);
      await settle(tester);

      expect(find.textContaining('(502)'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Volver a intentarlo'));
      await settle(tester);

      expect(find.text('Volver a intentarlo'), findsNothing);
      expect(find.text('Aciertos por sección'), findsOneWidget);
      // Las peticiones llevan la sesión del docente.
      expect(sent.last.headers['Authorization'], 'Bearer token-de-prueba');
    });
  });

  testWidgets('mientras carga por primera vez enseña que está cargando', (
    tester,
  ) async {
    final answer = Completer<http.Response>();
    serve((request) {
      if (request.url.path == '/api/analytics/summary') return answer.future;
      return withData(request);
    });
    await mount(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    answer.complete(
      await withData(
        http.Request(
          'GET',
          Uri.parse('http://servidor.de.prueba/api/analytics/summary'),
        ),
      ),
    );
    await settle(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Actividades hechas'), findsOneWidget);
  });

  group('con datos', () {
    testWidgets('cuenta hasta dónde llegan en cada sección', (tester) async {
      serve(withData);
      await mount(tester);
      await settle(tester);

      expect(find.text('Hasta dónde llegan'), findsOneWidget);
      // La fila de la sección dice por voz cuántos terminan cada actividad.
      expect(
        find.bySemanticsLabel('Conociendo Python. Lectura: 9. Quiz: 5.'),
        findsOneWidget,
      );
      expect(find.text('9'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // 20 de 40: un aprobado justo se pinta como aviso, no como acierto.
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(
        (bar.valueColor! as AlwaysStoppedAnimation<Color>).value,
        messages.warningForeground,
      );
    });

    testWidgets('con pocos datos dice qué falta en cada apartado', (
      tester,
    ) async {
      // Hay respuestas, pero ninguna sección ni pregunta llega a tres y
      // nadie ha terminado una actividad.
      stats.debugSeed(
        totalAnswers: 2,
        sections: const [
          SectionStats(
            sectionId: 'm1-s1',
            answered: 2,
            correct: 1,
            students: 1,
          ),
        ],
        questions: const [
          QuestionStats(
            sectionId: 'm1-s1',
            activity: 'quiz',
            questionIndex: 0,
            prompt: 'Casi sin respuestas',
            answered: 2,
            correct: 1,
          ),
        ],
      );
      await mount(tester);
      await settle(tester);

      expect(
        find.text(
          'Ninguna sección tiene todavía suficientes respuestas para comparar.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Todavía nadie ha terminado ninguna actividad.'),
        findsOneWidget,
      );
      expect(find.text('Todavía no hay tiempos medidos.'), findsOneWidget);
      expect(
        find.text('Todavía no hay preguntas con respuestas suficientes.'),
        findsOneWidget,
      );
      expect(find.text('Casi sin respuestas'), findsNothing);
    });

    testWidgets('las preguntas sin enunciado se nombran por su número', (
      tester,
    ) async {
      stats.debugSeed(
        totalAnswers: 30,
        totalCompletions: 3,
        questions: const [
          QuestionStats(
            sectionId: 'm1-s1',
            activity: 'quiz',
            questionIndex: 2,
            prompt: '',
            answered: 10,
            correct: 8,
          ),
          QuestionStats(
            sectionId: 'm1-s1',
            activity: 'quiz',
            questionIndex: 0,
            prompt: 'A medias',
            answered: 10,
            correct: 5,
          ),
        ],
      );
      await mount(tester);
      await settle(tester);

      expect(find.text('Pregunta 3'), findsOneWidget);
      expect(find.text('80 %'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);
      expect(find.text('Conociendo Python · 2 fallos de 10'), findsOneWidget);
    });
  });

  testWidgets('las preguntas lentas enseñan su tiempo medio en palabras', (
    tester,
  ) async {
    stats.debugSeed(
      totalAnswers: 20,
      totalCompletions: 2,
      questions: const [
        QuestionStats(
          sectionId: 'm1-s1',
          activity: 'quiz',
          questionIndex: 0,
          prompt: 'Enunciado confuso',
          answered: 20,
          correct: 19,
          avgSeconds: 95,
        ),
      ],
    );
    await mount(tester);
    await settle(tester);

    expect(find.text('Preguntas que más tiempo cuestan'), findsOneWidget);
    // En la lista de lentas manda el tiempo; en la de falladas, el acierto.
    expect(find.text('1 min 35 s'), findsOneWidget);
    expect(find.text('Conociendo Python · 1 fallos de 20'), findsOneWidget);
    expect(find.text('95 %'), findsOneWidget);
    expect(
      find.text('Conociendo Python · 1 fallos de 20 · 1 min 35 s'),
      findsOneWidget,
    );
    expect(find.text('Todavía no hay tiempos medidos.'), findsNothing);
  });

  group('el informe', () {
    testWidgets('se abre con el texto completo y se copia entero', (
      tester,
    ) async {
      final copied = <String>[];
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

      serve(withData);
      await mount(tester);
      await settle(tester);

      await tester.ensureVisible(find.text('Generar informe'));
      await tester.tap(find.text('Generar informe'));
      await settle(tester);

      expect(find.text('Informe del curso'), findsOneWidget);
      final shown = tester.widget<SelectableText>(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(SelectableText),
        ),
      );
      expect(shown.data, startsWith('INFORME DEL CURSO DE PYTHON'));
      expect(shown.data, contains('Respuestas registradas: 40'));
      expect(shown.data, contains('Estudiantes que han empezado: 1 de 1'));

      await tester.tap(find.text('Copiar'));
      await settle(tester);

      // Se copia exactamente lo que se ve, sin recortar nada.
      expect(copied, [shown.data]);
      expect(find.text('Informe copiado.'), findsOneWidget);
    });

    test('una pregunta sin enunciado no deja un hueco en el informe', () {
      stats.debugSeed(
        totalAnswers: 20,
        totalCompletions: 2,
        questions: const [
          QuestionStats(
            sectionId: 'm1-s1',
            activity: 'quiz',
            questionIndex: 0,
            prompt: '',
            answered: 10,
            correct: 2,
            avgSeconds: 70,
          ),
        ],
      );

      final report = buildCourseReport(stats, now: DateTime(2026, 3, 5));

      expect(report, contains('Generado el 05/03/2026'));
      // Aparece en las más falladas y en las más lentas.
      expect('(sin enunciado)'.allMatches(report).length, 2);
      expect(report, contains('8 fallos de 10 respuestas'));
      expect(report, contains('70 s de media'));
      // Sin estudiantes no se lista a nadie como «sin empezar».
      expect(report, isNot(contains('TODAVÍA NO HAN EMPEZADO')));
    });
  });
}
