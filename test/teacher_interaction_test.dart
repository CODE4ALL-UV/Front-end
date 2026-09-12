import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/course_section_edits.dart';
import 'package:flutter_code4all/ui/teacher/editors/capsule_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/example_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/exercise_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/quiz_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/videos_editor_screen.dart';

/// Usa los editores como los usaría un docente: añadiendo y quitando cosas.
///
/// Es donde más fácil se rompe algo. Cada elemento de una lista lleva sus
/// propios campos de texto, y al quitarlo hay que liberarlos; hacerlo mal
/// —liberar dos veces, o seguir usando uno liberado— tumba la pantalla en
/// cuanto se vuelve a dibujar.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Pulsa el botón de confirmar del diálogo de borrado.
  Future<void> confirm(WidgetTester tester) async {
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
    await settle(tester);
  }

  CourseSection sectionOf(int module, int number) =>
      PythonCourseCatalog.section(module, number)!;

  setUp(() {
    // Alto de sobra: los editores son largos y lo que no está dibujado no se
    // puede pulsar.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('cápsula: añadir y quitar consejos', () {
    testWidgets('añadir un consejo y luego borrarlo', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(CapsuleEditorScreen(capsule: sectionOf(1, 1).capsule)),
      );
      await settle(tester);

      final before = find.textContaining('Consejo ').evaluate().length;

      await tester.tap(find.text('Añadir consejo'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Consejo ').evaluate().length, before + 1);

      // Y se quita el último.
      await tester.tap(find.byIcon(Icons.close).last);
      await confirm(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Consejo ').evaluate().length, before);
    });

    testWidgets('quitar varios consejos seguidos no revienta', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(CapsuleEditorScreen(capsule: sectionOf(1, 1).capsule)),
      );
      await settle(tester);

      // Quitar dos seguidos es lo que destapa una liberación mal hecha.
      for (var i = 0; i < 2; i++) {
        final closes = find.byIcon(Icons.close);
        if (closes.evaluate().isEmpty) break;
        await tester.tap(closes.last);
        await confirm(tester);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('quiz: opciones de una pregunta', () {
    Future<void> openFirstQuestion(WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(QuizEditorScreen(questions: sectionOf(1, 1).quiz, title: 'Quiz')),
      );
      await settle(tester);

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await settle(tester);
    }

    testWidgets('añadir y quitar una opción', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await openFirstQuestion(tester);
      final before = find.byType(Radio<int>).evaluate().length;

      await tester.tap(find.text('Añadir opción'));
      await settle(tester);
      expect(find.byType(Radio<int>).evaluate().length, before + 1);

      await tester.tap(find.byIcon(Icons.close).last);
      await confirm(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Radio<int>).evaluate().length, before);
    });

    testWidgets('no deja bajar de dos opciones', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await openFirstQuestion(tester);

      // Se quitan opciones hasta que quedan dos.
      while (find.byType(Radio<int>).evaluate().length > 2) {
        await tester.tap(find.byIcon(Icons.close).last);
        await confirm(tester);
      }

      // La siguiente debe negarse, no dejar la pregunta sin opciones.
      await tester.tap(find.byIcon(Icons.close).last);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Radio<int>).evaluate().length, 2);
      expect(
        find.textContaining('al menos dos opciones'),
        findsOneWidget,
        reason: 'debe explicar por qué no se puede',
      );
    });

    testWidgets('una pregunta sin enunciado no se deja guardar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(const QuizEditorScreen(questions: [], title: 'Quiz')),
      );
      await settle(tester);

      await tester.tap(find.text('Añadir la primera pregunta'));
      await settle(tester);

      // Hay un "Listo" por cada editor apilado: el de la pantalla de
      // encima es el ultimo del arbol.
      await tester.tap(find.text('Listo').last);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('enunciado'), findsWidgets);
    });
  });

  group('lectura: páginas y bloques', () {
    testWidgets('añadir una página', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final section = sectionOf(1, 1);
      await tester.pumpWidget(
        wrap(ReadingEditorScreen(reading: section.reading, section: section)),
      );
      await settle(tester);

      final before = section.reading!.pages.length;
      await tester.tap(find.text('Añadir página'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Página ${before + 1}'), findsWidgets);
    });

    testWidgets('cambiar el tipo de un bloque conserva lo escrito', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final section = sectionOf(1, 1);
      await tester.pumpWidget(
        wrap(ReadingEditorScreen(reading: section.reading, section: section)),
      );
      await settle(tester);

      // Se abre la primera pagina por su titulo, que es inequivoco.
      final firstPage = section.reading!.pages.first;
      await tester.tap(find.text(firstPage.title).first);
      await settle(tester);
      expect(find.text('Bloques'), findsOneWidget);

      // Y dentro, su primer bloque.
      final firstBlock = firstPage.blocks.first;
      await tester.tap(
        find
            .text(firstBlock.title.isEmpty ? firstBlock.kind.label : firstBlock.title)
            .last,
      );
      await settle(tester);

      expect(find.text('Tipo de bloque'), findsOneWidget);

      // Se pasa a lista de puntos.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Lista de puntos'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Puntos'), findsOneWidget);

      // Y se vuelve a párrafo.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Párrafo'));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('videos: validación del enlace', () {
    testWidgets('un enlace que no es de YouTube se rechaza con explicación', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const VideosEditorScreen(videos: [])));
      await settle(tester);

      await tester.tap(find.text('Añadir el primer video'));
      await settle(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'https://www.youtube.com/watch?v=...'),
        'https://vimeo.com/12345',
      );
      await settle(tester);

      await tester.tap(find.text('Listo'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('No reconozco ese enlace'), findsOneWidget);
    });

    testWidgets('pegar un enlace bueno lo reconoce al momento', (tester) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const VideosEditorScreen(videos: [])));
      await settle(tester);

      await tester.tap(find.text('Añadir el primer video'));
      await settle(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'https://www.youtube.com/watch?v=...'),
        'https://youtu.be/dQw4w9WgXcQ',
      );
      await settle(tester);

      // Se lo dice antes de guardar, no después de fallar.
      expect(find.textContaining('Video reconocido'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ejemplo y ejercicio: añadir y quitar', () {
    testWidgets('añadir un paso al ejemplo y quitarlo', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(ExampleEditorScreen(example: sectionOf(1, 1).example)),
      );
      await settle(tester);

      await tester.tap(find.text('Añadir paso'));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close).last);
      await confirm(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('añadir una pareja al ejercicio y quitarla', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(ExerciseEditorScreen(exercise: sectionOf(1, 1).exercise)),
      );
      await settle(tester);

      await tester.tap(find.text('Añadir pareja'));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.close).last);
      await confirm(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('quitar una actividad entera', () {
    testWidgets('quitar la lectura deja la pantalla ofreciendo crearla', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final section = sectionOf(1, 1);
      await tester.pumpWidget(
        wrap(ReadingEditorScreen(reading: section.reading, section: section)),
      );
      await settle(tester);

      // El mismo icono aparece en la barra y en cada pagina de la lista.
      // El de la barra es el que quita la lectura entera.
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.delete_outline),
        ),
      );
      await confirm(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Crear la lectura'), findsOneWidget);
    });
  });
}
