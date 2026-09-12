import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/ui/teacher/teacher_report.dart';
import 'package:flutter_code4all/ui/teacher/teacher_stats_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';

/// Comprueba lo que el docente ve sobre el rendimiento de su clase.
///
/// Lo que más importa: que **no invente datos**. Un porcentaje sacado de dos
/// respuestas sueltas parece un resultado y no lo es, y enseñar ceros cuando
/// nadie ha contestado se lee como «lo hacen fatal» en lugar de «todavía no
/// hay nada».
void main() {
  final stats = CourseAnalyticsStore.instance;

  setUp(stats.debugReset);
  tearDown(stats.debugReset);

  SectionStats section(
    String id, {
    required int answered,
    required int correct,
    int students = 1,
    double? seconds,
  }) => SectionStats(
    sectionId: id,
    answered: answered,
    correct: correct,
    students: students,
    avgSeconds: seconds,
  );

  QuestionStats question(
    String id,
    int index, {
    required int answered,
    required int correct,
    String prompt = 'Una pregunta',
    double? seconds,
  }) => QuestionStats(
    sectionId: id,
    activity: 'quiz',
    questionIndex: index,
    prompt: prompt,
    answered: answered,
    correct: correct,
    avgSeconds: seconds,
  );

  StudentStats student(
    String name, {
    int answered = 0,
    int correct = 0,
    int sections = 0,
    int activities = 0,
  }) => StudentStats(
    userId: name.hashCode,
    name: name,
    email: '${name.toLowerCase()}@uv.edu.co',
    answered: answered,
    correct: correct,
    sectionsTouched: sections,
    activitiesDone: activities,
  );

  group('sin respuestas todavía', () {
    test('el curso se declara vacío, no en cero', () {
      expect(stats.isEmpty, isTrue);
      expect(stats.overallAccuracy, 0);
      expect(stats.hardestSections(), isEmpty);
    });

    test('el informe lo dice con palabras', () {
      final report = buildCourseReport(stats);

      expect(report, contains('Todavía no hay actividad'));
      // No debe insinuar que se responde mal.
      expect(report, isNot(contains('0 %')));
    });
  });

  group('qué tema cuesta más', () {
    setUp(() {
      stats.debugSeed(
        totalAnswers: 100,
        totalCompletions: 20,
        sections: [
          section('m1-s1', answered: 40, correct: 36),
          section('m2-s1', answered: 40, correct: 12),
          section('m3-s1', answered: 20, correct: 14),
        ],
      );
    });

    test('se ordenan de la peor a la mejor', () {
      final hard = stats.hardestSections();

      expect(hard.first.sectionId, 'm2-s1');
      expect(hard.last.sectionId, 'm1-s1');
    });

    test('el porcentaje global sale de todas las respuestas', () {
      // 36 + 12 + 14 = 62 de 100.
      expect(stats.overallAccuracy, closeTo(0.62, 0.001));
    });

    test('una sección con muy pocas respuestas no entra a comparar', () {
      // Con dos respuestas, un cero por ciento dice que casi nadie lo ha
      // hecho, no que el tema sea difícil. Colarla arriba del ranking haría
      // que el docente rehiciera un tema que nadie ha tocado.
      stats.debugSeed(
        totalAnswers: 42,
        totalCompletions: 10,
        sections: [
          section('m1-s1', answered: 40, correct: 20),
          section('m5-s1', answered: 2, correct: 0),
        ],
      );

      final hard = stats.hardestSections();
      expect(hard.map((s) => s.sectionId), isNot(contains('m5-s1')));
      expect(hard.single.sectionId, 'm1-s1');
    });

    test('la sección enseña el nombre del curso, no su identificador', () {
      final hard = stats.hardestSections();
      expect(hard.first.title, isNot('m2-s1'));
      expect(hard.first.title, isNotEmpty);
    });
  });

  group('qué preguntas se fallan', () {
    test('salen ordenadas por dificultad y solo con datos suficientes', () {
      stats.debugSeed(
        totalAnswers: 60,
        totalCompletions: 10,
        questions: [
          question('m1-s1', 0, answered: 20, correct: 18, prompt: 'Fácil'),
          question('m1-s1', 1, answered: 20, correct: 4, prompt: 'Difícil'),
          question('m1-s1', 2, answered: 1, correct: 0, prompt: 'Casi sin uso'),
        ],
      );

      final hard = stats.hardestQuestions();

      expect(hard.first.prompt, 'Difícil');
      expect(hard.map((q) => q.prompt), isNot(contains('Casi sin uso')));
    });
  });

  group('estudiantes', () {
    setUp(() {
      stats.debugSeed(
        totalAnswers: 30,
        totalCompletions: 12,
        sections: [section('m1-s1', answered: 30, correct: 20, students: 2)],
        students: [
          student('Ana', answered: 20, correct: 18, sections: 3, activities: 6),
          student('Beto', answered: 10, correct: 2, sections: 1, activities: 2),
          student('Carla'),
        ],
      );
    });

    test('quien no ha empezado se distingue de quien va mal', () {
      final carla = stats.students.firstWhere((s) => s.name == 'Carla');
      final beto = stats.students.firstWhere((s) => s.name == 'Beto');

      expect(carla.hasNotStarted, isTrue);
      expect(beto.hasNotStarted, isFalse);
      // Los dos tienen mal porcentaje, pero significan cosas distintas.
      expect(beto.accuracy, lessThan(0.5));
    });

    test('solo cuenta como activo quien ha respondido algo', () {
      expect(stats.activeStudents, 2);
      expect(stats.students.length, 3);
    });
  });

  group('el informe', () {
    setUp(() {
      stats.debugSeed(
        totalAnswers: 80,
        totalCompletions: 25,
        sections: [
          section('m1-s1', answered: 40, correct: 36),
          section('m2-s1', answered: 40, correct: 10),
        ],
        questions: [
          question('m2-s1', 0, answered: 40, correct: 8, prompt: 'La peor'),
        ],
        students: [
          student('Ana', answered: 40, correct: 30, activities: 8),
          student('Sin empezar'),
        ],
      );
    });

    test('dice cuál es el tema que más cuesta, con palabras', () {
      final report = buildCourseReport(stats, now: DateTime(2026, 9, 12));

      expect(report, contains('El tema que más cuesta'));
      expect(report, contains('El que mejor va'));
    });

    test('lista a quien no ha empezado', () {
      final report = buildCourseReport(stats);

      expect(report, contains('TODAVÍA NO HAN EMPEZADO'));
      expect(report, contains('Sin empezar'));
    });

    test('incluye la pregunta más fallada con su enunciado', () {
      expect(buildCourseReport(stats), contains('La peor'));
    });

    test('avisa de que pocos datos dicen poco', () {
      // Sin esa advertencia, alguien pegaría un 0 % de tres respuestas en una
      // conclusión de tesis como si fuera un hallazgo.
      expect(buildCourseReport(stats), contains('dicen poco'));
    });

    test('lleva la fecha para saber a cuándo corresponde', () {
      final report = buildCourseReport(stats, now: DateTime(2026, 9, 12));
      expect(report, contains('12/09/2026'));
    });
  });

  group('las pantallas se dibujan', () {
    Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    );

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('estadísticas sin datos invita en vez de asustar', (
      tester,
    ) async {
      stats.debugSeed(totalAnswers: 0);

      await tester.pumpWidget(wrap(const TeacherStatsScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Todavía no hay actividad'), findsOneWidget);
    });

    testWidgets('estadísticas con datos enseña los temas', (tester) async {
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      stats.debugSeed(
        totalAnswers: 80,
        totalCompletions: 25,
        sections: [
          section('m1-s1', answered: 40, correct: 36),
          section('m2-s1', answered: 40, correct: 10),
        ],
        questions: [
          question('m2-s1', 0, answered: 40, correct: 8, prompt: 'La peor'),
        ],
        students: [student('Ana', answered: 40, correct: 30, activities: 8)],
      );

      await tester.pumpWidget(wrap(const TeacherStatsScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Aciertos por sección'), findsOneWidget);
      expect(find.text('Generar informe'), findsOneWidget);
    });

    testWidgets('estadísticas caben a 320 px con el texto al doble', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      stats.debugSeed(
        totalAnswers: 80,
        totalCompletions: 25,
        sections: [section('m1-s1', answered: 40, correct: 36)],
        questions: [
          question('m1-s1', 0, answered: 40, correct: 8, prompt: 'Una pregunta larga de verdad para ver si cabe'),
        ],
        students: [student('Ana', answered: 40, correct: 30, activities: 8)],
      );

      await tester.pumpWidget(
        wrap(const TeacherStatsScreen(), textScale: 2.0),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('la lista de estudiantes pone arriba a quien no empezó', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      stats.debugSeed(
        totalAnswers: 30,
        totalCompletions: 12,
        students: [
          student('Ana', answered: 20, correct: 18, activities: 5),
          student('Zoe'),
        ],
      );

      await tester.pumpWidget(wrap(const TeacherStudentsScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Sin empezar'), findsOneWidget);
      expect(find.textContaining('1 sin empezar'), findsOneWidget);
    });

    testWidgets('sin estudiantes lo dice claro', (tester) async {
      stats.debugSeed(totalAnswers: 0, students: []);

      await tester.pumpWidget(wrap(const TeacherStudentsScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('ningún estudiante'), findsOneWidget);
    });
  });

  group('cuánto se tarda en responder', () {
    test('las lentas salen primero, y solo las que tienen tiempo medido', () {
      stats.debugSeed(
        totalAnswers: 60,
        totalCompletions: 10,
        questions: [
          question('m1-s1', 0, answered: 20, correct: 18, prompt: 'Rápida', seconds: 8),
          question('m1-s1', 1, answered: 20, correct: 19, prompt: 'Lenta', seconds: 95),
          question('m1-s1', 2, answered: 20, correct: 5, prompt: 'Sin medir'),
        ],
      );

      final slow = stats.slowestQuestions();

      expect(slow.first.prompt, 'Lenta');
      // Sin tiempo medido no puede entrar: contarla como cero la pondria la
      // mas rapida de todas, que es justo lo contrario de lo que se sabe.
      expect(slow.map((q) => q.prompt), isNot(contains('Sin medir')));
    });

    test('una pregunta acertada pero lenta se distingue de una fallada', () {
      stats.debugSeed(
        totalAnswers: 40,
        totalCompletions: 5,
        questions: [
          question('m1-s1', 0, answered: 20, correct: 19, prompt: 'Confusa', seconds: 95),
          question('m1-s1', 1, answered: 20, correct: 3, prompt: 'Dificil', seconds: 10),
        ],
      );

      expect(stats.slowestQuestions().first.prompt, 'Confusa');
      expect(stats.hardestQuestions().first.prompt, 'Dificil');
    });

    test('el tiempo se escribe en palabras, no en milisegundos', () {
      expect(formatSeconds(8), '8 s');
      expect(formatSeconds(59.4), '59 s');
      expect(formatSeconds(60), '1 min');
      expect(formatSeconds(130), '2 min 10 s');
    });

    test('el informe incluye las preguntas lentas', () {
      stats.debugSeed(
        totalAnswers: 40,
        totalCompletions: 5,
        sections: [section('m1-s1', answered: 40, correct: 20, seconds: 22.5)],
        questions: [
          question('m1-s1', 0, answered: 40, correct: 38, prompt: 'La lenta', seconds: 95),
        ],
        students: [student('Ana', answered: 40, correct: 38, activities: 4)],
      );

      final report = buildCourseReport(stats);
      expect(report, contains('MÁS TIEMPO CUESTAN'));
      expect(report, contains('La lenta'));
      expect(report, contains('95 s'));
      // Y el tiempo medio de la seccion.
      expect(report, contains('23 s de media'));
    });
  });
}
