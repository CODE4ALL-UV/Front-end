import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_quiz_screen.dart';

/// Evita que las pruebas dependan del almacenamiento seguro real
/// del dispositivo o de una plataforma nativa.
void _setAuthenticatedStorage() {
  FlutterSecureStorage.setMockInitialValues({
    'token': 'test-token',
    'auth_token': 'test-token',
    'access_token': 'test-token',
    'accessToken': 'test-token',
    'authToken': 'test-token',
    'jwt': 'test-token',
    'user_token': 'test-token',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CourseModule module;
  late CourseSection section;
  late List<QuizQuestion> questions;

  setUp(() {
    // Debe ejecutarse antes de que el test utilice el almacenamiento.
    _setAuthenticatedStorage();

    questions = const [
      QuizQuestion(
        prompt: '¿Cuánto es 2 + 2?',
        options: ['3', '4', '5'],
        correctIndex: 1,
        explanation: 'El resultado de sumar 2 y 2 es 4.',
      ),
      QuizQuestion(
        prompt: '¿Cuánto es 3 + 3?',
        options: ['5', '6', '7'],
        correctIndex: 1,
        explanation: 'El resultado de sumar 3 y 3 es 6.',
      ),
      QuizQuestion(
        prompt: '¿Cuánto es 4 + 4?',
        options: ['7', '8', '9'],
        correctIndex: 1,
        explanation: 'El resultado de sumar 4 y 4 es 8.',
      ),
    ];

    section = CourseSection(
      id: 'test-section-quiz',
      moduleNumber: 1,
      number: 1,
      title: 'Prueba de cuestionarios',
      summary: 'Sección utilizada para probar el cuestionario.',
      objectives: const ['Validar el funcionamiento del cuestionario.'],
    );

    module = CourseModule(
      number: 1,
      title: 'Módulo de pruebas',
      sections: [section],
    );
  });

  Future<void> pumpQuiz(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: SectionQuizScreen(
          module: module,
          section: section,
          questions: questions,
          activityKind: CourseActivityKind.quiz,
          activityLabel: 'Quiz',
          activityIcon: Icons.quiz,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> answerQuestion(
    WidgetTester tester, {
    required String option,
    required bool isLastQuestion,
  }) async {
    final optionFinder = find.text(option);

    expect(
      optionFinder,
      findsWidgets,
      reason: 'La opción "$option" debería estar visible.',
    );

    await tester.ensureVisible(optionFinder.first);
    await tester.tap(optionFinder.first);
    await tester.pumpAndSettle();

    final buttonLabel = isLastQuestion ? 'Ver resultado' : 'Siguiente pregunta';

    final buttonFinder = find.widgetWithText(ElevatedButton, buttonLabel);

    expect(
      buttonFinder,
      findsOneWidget,
      reason: 'Debería existir el botón "$buttonLabel".',
    );

    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);

    // Permite que avance la operación asíncrona de finalización.
    await tester.pumpAndSettle();
  }

  group('SectionQuizScreen', () {
    testWidgets('una pregunta con más de seis opciones no rompe el quiz', (
      tester,
    ) async {
      // El editor del docente deja añadir todas las opciones que quiera; la
      // lista fija de seis letras lanzaba un RangeError con la séptima.
      questions = const [
        QuizQuestion(
          prompt: '¿Cuál es par?',
          options: ['1', '3', '5', '7', '9', '11', '12'],
          correctIndex: 6,
          explanation: 'El 12 es divisible entre 2.',
        ),
      ];
      await pumpQuiz(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('G'), findsOneWidget);

      await tester.ensureVisible(find.text('1'));
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('G: 12'), findsWidgets);
    });

    testWidgets('muestra la primera pregunta y sus opciones', (tester) async {
      await pumpQuiz(tester);

      expect(find.text('¿Cuánto es 2 + 2?'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      expect(find.text('Siguiente pregunta'), findsOneWidget);
      expect(find.text('Ver resultado'), findsNothing);
    });

    testWidgets('permite responder y avanzar a la siguiente pregunta', (
      tester,
    ) async {
      await pumpQuiz(tester);

      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuánto es 2 + 2?'), findsOneWidget);
      expect(find.text('El resultado de sumar 2 y 2 es 4.'), findsOneWidget);

      await tester.ensureVisible(find.text('Siguiente pregunta'));
      await tester.tap(find.text('Siguiente pregunta'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuánto es 3 + 3?'), findsOneWidget);
      expect(find.text('¿Cuánto es 2 + 2?'), findsNothing);
    });

    testWidgets(
      'aprueba cuando obtiene al menos el 60 % de respuestas correctas',
      (tester) async {
        await pumpQuiz(tester);

        // Dos respuestas correctas y una incorrecta: 2/3 = 66,7 %.
        await answerQuestion(tester, option: '4', isLastQuestion: false);

        await answerQuestion(tester, option: '6', isLastQuestion: false);

        await answerQuestion(tester, option: '7', isLastQuestion: true);

        expect(find.text('¡Actividad superada!'), findsOneWidget);
        expect(find.text('Aún no es suficiente'), findsNothing);
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.text('Volver'), findsOneWidget);
      },
    );

    testWidgets(
      'muestra el resultado de reprobación cuando no alcanza el 60 %',
      (tester) async {
        await pumpQuiz(tester);

        // Una respuesta correcta y dos incorrectas: 1/3 = 33,3 %.
        await answerQuestion(tester, option: '4', isLastQuestion: false);

        await answerQuestion(tester, option: '5', isLastQuestion: false);

        await answerQuestion(tester, option: '7', isLastQuestion: true);

        expect(find.text('Aún no es suficiente'), findsOneWidget);
        expect(find.text('¡Actividad superada!'), findsNothing);
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.text('Volver'), findsOneWidget);
      },
    );

    testWidgets('reinicia el cuestionario al pulsar Reintentar', (
      tester,
    ) async {
      await pumpQuiz(tester);

      await answerQuestion(tester, option: '4', isLastQuestion: false);

      await answerQuestion(tester, option: '6', isLastQuestion: false);

      await answerQuestion(tester, option: '8', isLastQuestion: true);

      expect(find.text('¡Actividad superada!'), findsOneWidget);

      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuánto es 2 + 2?'), findsOneWidget);
      expect(find.text('¡Actividad superada!'), findsNothing);
      expect(find.text('Siguiente pregunta'), findsOneWidget);
    });
  });
}
