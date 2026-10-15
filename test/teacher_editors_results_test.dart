import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/editors/capsule_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/example_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/exercise_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/quiz_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/videos_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

/// Lo que devuelve cada editor de actividad al pulsar «Listo».
///
/// Los editores de videos, quiz, ejercicio, cápsula y ejemplo se abren desde
/// la sección y devuelven lo escrito. Aquí se comprueba ese resultado: que lo
/// editado vuelva tal cual, que lo vacío no se cuele como contenido, que lo
/// reordenado vuelva en su orden y que quitar la actividad entera devuelva
/// «nada». Y también que una pregunta o un video a medio hacer no se dejen
/// cerrar, con un aviso que diga qué falta.
void main() {
  late Object? result;
  late bool returned;

  /// Abre [editor] desde una pantalla de partida para recoger lo que
  /// devuelve al cerrarse.
  Future<void> open(WidgetTester tester, Widget editor) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    returned = false;
    result = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(
                    context,
                  ).push<Object?>(MaterialPageRoute(builder: (_) => editor));
                  returned = true;
                },
                child: const Text('Abrir el editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir el editor'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester) =>
      tap(tester, find.text('Listo').last);

  Future<void> confirm(WidgetTester tester) =>
      tap(tester, find.widgetWithText(FilledButton, 'Borrar'));

  Finder field(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(TeacherField),
    ),
    matching: find.byType(TextField),
  );

  /// Los campos de las opciones de una pregunta, en orden.
  Finder options() => find.descendant(
    of: find.byType(RadioGroup<int>),
    matching: find.byType(TextField),
  );

  group('videos', () {
    const intro = SectionVideo(
      title: 'Intro',
      youtubeId: 'dQw4w9WgXcQ',
      description: 'Para empezar',
      duration: '3:00',
      transcript: 'Hola.',
    );
    const extra = SectionVideo(
      title: 'Extra',
      youtubeId: 'abcdefghijk',
      description: '',
    );

    testWidgets('editar un video conserva lo que no se tocó', (tester) async {
      await open(tester, const VideosEditorScreen(videos: [intro, extra]));

      await tap(tester, find.text('Intro'));
      expect(find.text('Editar video'), findsOneWidget);
      expect(find.text('Video reconocido: dQw4w9WgXcQ'), findsOneWidget);

      await tester.enterText(field('Título'), ' Introducción ');
      await done(tester);
      await done(tester);

      final videos = result! as List<SectionVideo>;
      expect(videos.first.title, 'Introducción');
      expect(videos.first.youtubeId, 'dQw4w9WgXcQ');
      expect(videos.first.transcript, 'Hola.');
      expect(videos.first.description, 'Para empezar');
      expect(videos.last.title, 'Extra');
    });

    testWidgets('un video sin título no se deja cerrar', (tester) async {
      await open(tester, const VideosEditorScreen(videos: [intro]));

      await tap(tester, find.text('Intro'));
      await tester.enterText(field('Título'), '   ');
      await done(tester);

      expect(find.text('Ponle un título al video.'), findsOneWidget);
      expect(find.text('Editar video'), findsOneWidget);

      // Al volver a escribir, el aviso se quita.
      await tester.enterText(field('Título'), 'Con título');
      await tester.pumpAndSettle();
      expect(find.text('Ponle un título al video.'), findsNothing);
    });

    testWidgets('se suben y se bajan', (tester) async {
      await open(tester, const VideosEditorScreen(videos: [intro, extra]));

      await tap(tester, find.byTooltip('Bajar Intro'));
      await tap(tester, find.byTooltip('Subir Intro'));
      await tap(tester, find.byTooltip('Subir Extra'));
      await done(tester);

      final videos = result! as List<SectionVideo>;
      expect(videos.map((v) => v.title), ['Extra', 'Intro']);
    });

    testWidgets('se borran con confirmación', (tester) async {
      await open(tester, const VideosEditorScreen(videos: [intro, extra]));

      // Al que no tiene transcripción se le avisa en la lista.
      expect(find.text('abcdefghijk · sin transcripción'), findsOneWidget);
      expect(find.text('dQw4w9WgXcQ · 3:00'), findsOneWidget);

      await tap(tester, find.byTooltip('Borrar Intro'));
      expect(find.text('¿Borrar el video "Intro"?'), findsOneWidget);
      await confirm(tester);
      await tap(tester, find.byTooltip('Borrar Extra'));
      await tap(tester, find.text('Cancelar'));
      await done(tester);

      final videos = result! as List<SectionVideo>;
      expect(videos.map((v) => v.title), ['Extra']);
    });

    testWidgets('a un video sin enlace se le avisa en la lista', (
      tester,
    ) async {
      await open(
        tester,
        const VideosEditorScreen(
          videos: [
            SectionVideo(title: 'Sin enlace', youtubeId: '', description: ''),
          ],
        ),
      );

      expect(find.text('⚠ falta el enlace del video'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byTooltip('Subir Sin enlace'),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('quiz', () {
    const first = QuizQuestion(
      prompt: '¿Qué es print?',
      options: ['Una función', 'Una variable', 'Un número'],
      correctIndex: 0,
      explanation: 'Muestra texto.',
    );
    const second = QuizQuestion(
      prompt: '¿Qué es 3?',
      options: ['Un texto', 'Un número'],
      correctIndex: 1,
    );

    testWidgets('editar una pregunta cambia el enunciado y la correcta', (
      tester,
    ) async {
      await open(
        tester,
        const QuizEditorScreen(questions: [first, second], title: 'Quiz'),
      );

      expect(find.text('3 opciones · correcta: Una función'), findsOneWidget);
      await tap(tester, find.text('¿Qué es print?'));
      expect(find.text('Editar pregunta'), findsOneWidget);

      await tester.enterText(field('Enunciado'), ' ¿Para qué sirve print? ');
      await tester.enterText(field('Explicación'), ' Escribe en pantalla. ');
      await tap(tester, find.byType(Radio<int>).at(2));
      await done(tester);

      expect(find.text('3 opciones · correcta: Un número'), findsOneWidget);
      await done(tester);

      final questions = result! as List<QuizQuestion>;
      expect(questions.first.prompt, '¿Para qué sirve print?');
      expect(questions.first.correctOption, 'Un número');
      expect(questions.first.explanation, 'Escribe en pantalla.');
      expect(questions.last.prompt, '¿Qué es 3?');
    });

    testWidgets('las preguntas se reordenan', (tester) async {
      await open(
        tester,
        const QuizEditorScreen(questions: [first, second], title: 'Quiz'),
      );

      await tap(tester, find.byTooltip('Subir ¿Qué es 3?'));
      await tap(tester, find.byTooltip('Bajar ¿Qué es 3?'));
      await tap(tester, find.byTooltip('Bajar ¿Qué es print?'));
      await done(tester);

      final questions = result! as List<QuizQuestion>;
      expect(questions.map((q) => q.prompt), ['¿Qué es 3?', '¿Qué es print?']);
    });

    testWidgets('borrar una opción anterior a la correcta no cambia cuál es', (
      tester,
    ) async {
      const question = QuizQuestion(
        prompt: '¿Cuál es un número?',
        options: ['"a"', 'True', '7'],
        correctIndex: 2,
      );
      await open(
        tester,
        const QuizEditorScreen(questions: [question], title: 'Quiz'),
      );

      await tap(tester, find.text('¿Cuál es un número?'));
      await tap(tester, find.byTooltip('Quitar la opción 1'));
      expect(find.text('¿Borrar esta opción?'), findsOneWidget);
      await confirm(tester);
      await done(tester);
      await done(tester);

      final edited = (result! as List<QuizQuestion>).single;
      expect(edited.options, ['True', '7']);
      expect(edited.correctOption, '7');
    });

    testWidgets('borrar la opción correcta marca la primera como correcta', (
      tester,
    ) async {
      const question = QuizQuestion(
        prompt: '¿Cuál?',
        options: ['a', 'b', 'c'],
        correctIndex: 1,
      );
      await open(
        tester,
        const QuizEditorScreen(questions: [question], title: 'Quiz'),
      );

      await tap(tester, find.text('¿Cuál?'));
      await tap(tester, find.byTooltip('Quitar la opción 2'));
      await confirm(tester);
      await done(tester);
      await done(tester);

      final edited = (result! as List<QuizQuestion>).single;
      expect(edited.options, ['a', 'c']);
      expect(edited.correctIndex, 0);
    });

    testWidgets('cancelar al borrar una opción la deja como estaba', (
      tester,
    ) async {
      await open(
        tester,
        const QuizEditorScreen(questions: [first], title: 'Quiz'),
      );

      await tap(tester, find.text('¿Qué es print?'));
      await tap(tester, find.byTooltip('Quitar la opción 3'));
      await tap(tester, find.text('Cancelar'));

      expect(options(), findsNWidgets(3));
    });

    testWidgets('una opción vacía no se deja cerrar hasta escribirla', (
      tester,
    ) async {
      await open(
        tester,
        const QuizEditorScreen(questions: [second], title: 'Quiz'),
      );

      await tap(tester, find.text('¿Qué es 3?'));
      await tap(tester, find.text('Añadir opción'));
      await done(tester);

      expect(
        find.text(
          'Hay opciones vacías. Escríbelas o quítalas antes de seguir.',
        ),
        findsOneWidget,
      );

      await tester.enterText(options().last, 'Una lista');
      await tester.pumpAndSettle();
      expect(find.textContaining('Hay opciones vacías'), findsNothing);

      await done(tester);
      await done(tester);
      expect((result! as List<QuizQuestion>).single.options, [
        'Un texto',
        'Un número',
        'Una lista',
      ]);
    });

    testWidgets('la lista avisa de las preguntas a medio hacer', (
      tester,
    ) async {
      await open(
        tester,
        const QuizEditorScreen(
          questions: [
            QuizQuestion(prompt: '', options: ['sola'], correctIndex: 0),
            QuizQuestion(
              prompt: 'Con hueco',
              options: ['a', ' '],
              correctIndex: 0,
            ),
          ],
          title: 'Quiz',
        ),
      );

      expect(find.text('Pregunta sin enunciado'), findsOneWidget);
      expect(
        find.text('⚠ falta el enunciado, faltan opciones'),
        findsOneWidget,
      );
      expect(find.text('⚠ hay opciones vacías'), findsOneWidget);
    });

    testWidgets('salir de una pregunta sin «Listo» no la cambia', (
      tester,
    ) async {
      await open(
        tester,
        const QuizEditorScreen(questions: [first], title: 'Quiz'),
      );

      await tap(tester, find.text('¿Qué es print?'));
      await tester.enterText(field('Enunciado'), 'A medias');
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      await done(tester);

      expect((result! as List<QuizQuestion>).single.prompt, '¿Qué es print?');
    });
  });

  group('ejercicio', () {
    // El módulo 1, sección 2 trae un ejercicio de emparejar con cuatro parejas.
    final exercise = PythonCourseCatalog.section(1, 2)!.exercise!;

    testWidgets('quitar una pareja y dejar otra vacía no las devuelve', (
      tester,
    ) async {
      await open(tester, ExerciseEditorScreen(exercise: exercise));

      // Las parejas que ya había vienen escritas.
      expect(
        tester.widget<TextField>(field('Concepto').first).controller!.text,
        exercise.pairs.first.concept,
      );

      await tap(tester, find.byTooltip('Quitar la pareja 2'));
      expect(find.text('¿Borrar la pareja 2?'), findsOneWidget);
      await confirm(tester);
      await tap(tester, find.text('Añadir pareja'));
      await done(tester);

      final edited = result! as SectionExercise;
      expect(edited.pairs.map((p) => p.concept), [
        exercise.pairs[0].concept,
        exercise.pairs[2].concept,
        exercise.pairs[3].concept,
      ]);
    });

    testWidgets('las preguntas del ejercicio se editan en su propio editor', (
      tester,
    ) async {
      await open(tester, ExerciseEditorScreen(exercise: exercise));
      expect(find.text('Sin preguntas'), findsOneWidget);

      await tap(tester, find.text('Preguntas del ejercicio'));
      expect(
        tester.widget<QuizEditorScreen>(find.byType(QuizEditorScreen)).title,
        'Preguntas del ejercicio',
      );

      await tap(tester, find.text('Añadir la primera pregunta'));
      await tester.enterText(field('Enunciado'), '¿Qué es una lista?');
      await tester.enterText(options().at(0), 'Una colección');
      await tester.enterText(options().at(1), 'Un número');
      await done(tester);
      await done(tester);

      expect(find.text('1 pregunta'), findsOneWidget);
      await done(tester);

      final edited = result! as SectionExercise;
      expect(edited.questions.single.prompt, '¿Qué es una lista?');
      expect(edited.questions.single.correctOption, 'Una colección');
      // Las parejas siguen ahí.
      expect(edited.pairs, hasLength(exercise.pairs.length));
    });

    testWidgets('quitar el ejercicio entero devuelve una sección sin él', (
      tester,
    ) async {
      await open(tester, ExerciseEditorScreen(exercise: exercise));

      await tap(tester, find.byTooltip('Quitar de la sección'));
      expect(find.text('¿Borrar el ejercicio?'), findsOneWidget);
      await confirm(tester);

      expect(find.text('Esta sección no tiene ejercicio.'), findsOneWidget);
      await done(tester);

      expect(returned, isTrue);
      expect(result, isNull);
    });
  });

  group('cápsula', () {
    const capsule = KnowledgeCapsule(
      title: 'Nombres',
      headline: 'Nombra bien',
      intro: 'Intro',
      tips: [CapsuleTip(title: 'Claro', body: 'Usa nombres claros.')],
      closing: 'Fin',
      badCode: 'x = 1',
      goodCode: 'edad = 1',
      badCodeCaption: 'No dice nada',
      goodCodeCaption: 'Se entiende',
    );

    testWidgets('vaciar la comparación de código la quita', (tester) async {
      await open(tester, const CapsuleEditorScreen(capsule: capsule));

      await tester.enterText(field('Cómo NO hacerlo'), '  ');
      await tester.enterText(field('Qué está mal, en palabras'), '');
      await tester.enterText(field('Cierre'), ' Hasta pronto ');
      await tap(tester, find.text('Añadir consejo'));
      await done(tester);

      final edited = result! as KnowledgeCapsule;
      expect(edited.badCode, isNull);
      expect(edited.badCodeCaption, isNull);
      expect(edited.goodCode, 'edad = 1');
      expect(edited.hasCodeComparison, isFalse);
      expect(edited.closing, 'Hasta pronto');
      // El consejo nuevo quedó vacío: no se cuela como consejo.
      expect(edited.tips.map((t) => t.title), ['Claro']);
    });

    testWidgets('quitar la cápsula entera devuelve una sección sin ella', (
      tester,
    ) async {
      await open(tester, const CapsuleEditorScreen(capsule: capsule));

      await tap(tester, find.byTooltip('Quitar de la sección'));
      expect(find.text('¿Borrar la cápsula entera?'), findsOneWidget);
      await tap(tester, find.text('Cancelar'));
      expect(find.text('Consejos'), findsOneWidget);

      await tap(tester, find.byTooltip('Quitar de la sección'));
      await confirm(tester);
      expect(
        find.text('Esta sección no tiene cápsula de conocimiento.'),
        findsOneWidget,
      );
      await done(tester);

      expect(returned, isTrue);
      expect(result, isNull);
    });
  });

  group('ejemplo', () {
    const example = CodeExample(
      title: 'Suma',
      description: 'Suma dos números',
      code: 'print(1 + 2)',
      output: '3',
      codeCaption: 'Imprime la suma',
      steps: [ExampleStep(code: '1 + 2', explanation: 'Suma.')],
    );

    testWidgets('el código y su salida vuelven tal cual se escribieron', (
      tester,
    ) async {
      await open(tester, const ExampleEditorScreen(example: example));

      // El código no se recorta: la sangría es parte de Python.
      await tester.enterText(field('Código completo'), 'if x:\n    print(x)\n');
      await tester.enterText(field('Lo que aparece al ejecutarlo'), '5\n');
      await tester.enterText(field('Qué hace, en palabras'), ' Muestra x ');
      await tap(tester, find.text('Añadir paso'));
      await done(tester);

      final edited = result! as CodeExample;
      expect(edited.code, 'if x:\n    print(x)\n');
      expect(edited.output, '5\n');
      expect(edited.codeCaption, 'Muestra x');
      // El paso que se añadió vacío no cuenta.
      expect(edited.steps, hasLength(1));
      expect(edited.title, 'Suma');
    });

    testWidgets('quitar el ejemplo entero devuelve una sección sin él', (
      tester,
    ) async {
      await open(tester, const ExampleEditorScreen(example: example));

      await tap(tester, find.byTooltip('Quitar de la sección'));
      expect(find.text('¿Borrar el ejemplo?'), findsOneWidget);
      await confirm(tester);

      expect(
        find.text('Esta sección no tiene ejemplo comentado.'),
        findsOneWidget,
      );
      await done(tester);

      expect(returned, isTrue);
      expect(result, isNull);
    });
  });
}
