import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/editors/editor_scaffold.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

/// Lo que devuelve el editor de lectura después de tocar páginas y bloques.
///
/// La lectura tiene tres niveles —lectura, página y bloque— y cada uno se
/// edita en su propia pantalla. Un fallo típico es que el cambio se vea en la
/// pantalla de abajo pero no suba hasta arriba, y el docente pierda el texto
/// al guardar. Por eso cada prueba recorre el camino entero y mira lo que el
/// editor devuelve al pulsar «Listo», no solo lo que se dibuja.
void main() {
  final section = PythonCourseCatalog.section(1, 1)!;

  late SectionReading? result;

  /// Si se salió con «Listo». La flecha de atrás no devuelve nada.
  late bool returned;

  /// Abre el editor desde una pantalla de partida para recoger lo que
  /// devuelve al cerrarse.
  Future<void> open(WidgetTester tester, SectionReading? reading) async {
    tester.view.physicalSize = const Size(800, 2400);
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
                  final popped = await Navigator.of(context)
                      .push<EditorResult<SectionReading>>(
                        MaterialPageRoute(
                          builder: (_) => ReadingEditorScreen(
                            reading: reading,
                            section: section,
                          ),
                        ),
                      );
                  result = popped?.value;
                  returned = popped != null;
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

  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  SectionReading readingOf(List<ReadingPage> pages) =>
      SectionReading(title: 'Lectura', intro: 'Intro', pages: pages);

  ReadingPage page(String title, [List<ReadingBlock> blocks = const []]) =>
      ReadingPage(title: title, summary: '', blocks: blocks);

  group('la lectura y sus páginas', () {
    testWidgets('el título y la introducción vuelven recortados', (
      tester,
    ) async {
      await open(tester, readingOf([page('A')]));

      await tester.enterText(field('Título de la lectura'), '  Variables  ');
      await tester.enterText(field('Introducción'), ' Qué es una variable. ');
      await done(tester);

      expect(returned, isTrue);
      expect(result!.title, 'Variables');
      expect(result!.intro, 'Qué es una variable.');
      expect(result!.pages.single.title, 'A');
    });

    testWidgets('editar una página cambia su título y su resumen', (
      tester,
    ) async {
      await open(tester, readingOf([page('A'), page('B')]));

      await tap(tester, find.text('A'));
      expect(find.text('Página 1'), findsOneWidget);
      await tester.enterText(field('Título de la página'), ' Primeros pasos ');
      await tester.enterText(field('Resumen'), ' De qué va. ');
      await done(tester);

      // La lista ya enseña el título nuevo y avisa de que está vacía.
      expect(find.text('Primeros pasos'), findsOneWidget);
      expect(find.text('⚠ sin contenido todavía'), findsNWidgets(2));

      await done(tester);
      expect(result!.pages.first.title, 'Primeros pasos');
      expect(result!.pages.first.summary, 'De qué va.');
      expect(result!.pages.last.title, 'B');
    });

    testWidgets('las páginas se suben y se bajan, sin salirse de la lista', (
      tester,
    ) async {
      await open(tester, readingOf([page('A'), page('B'), page('C')]));

      // La primera no sube y la última no baja.
      expect(button(tester, 'Subir A').onPressed, isNull);
      expect(button(tester, 'Bajar C').onPressed, isNull);

      await tap(tester, find.byTooltip('Bajar A'));
      await tap(tester, find.byTooltip('Subir C'));
      await done(tester);

      expect(result!.pages.map((p) => p.title), ['B', 'C', 'A']);
    });

    testWidgets('borrar una página pide confirmación', (tester) async {
      await open(tester, readingOf([page('A'), page('B'), page('C')]));

      await tap(tester, find.byTooltip('Borrar B'));
      expect(find.text('¿Borrar la página "B"?'), findsOneWidget);
      await tap(tester, find.text('Cancelar'));
      expect(find.text('B'), findsOneWidget);

      await tap(tester, find.byTooltip('Borrar B'));
      await confirm(tester);
      expect(find.text('B'), findsNothing);

      await done(tester);
      expect(result!.pages.map((p) => p.title), ['A', 'C']);
    });

    testWidgets('la última página no se puede borrar', (tester) async {
      await open(tester, readingOf([page('Única')]));

      expect(button(tester, 'Borrar Única').onPressed, isNull);
    });

    testWidgets('quitar la lectura entera devuelve una sección sin lectura', (
      tester,
    ) async {
      await open(tester, readingOf([page('A')]));

      await tap(tester, find.byTooltip('Quitar la lectura de la sección'));
      expect(find.text('¿Borrar la lectura entera?'), findsOneWidget);
      await confirm(tester);
      await done(tester);

      expect(returned, isTrue);
      expect(result, isNull);
    });
  });

  group('los bloques de una página', () {
    testWidgets('editar un bloque sube el cambio hasta la lectura', (
      tester,
    ) async {
      await open(
        tester,
        readingOf([
          page('A', const [
            ReadingBlock.paragraph(title: 'Antes', body: 'Texto viejo'),
          ]),
        ]),
      );

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Antes'));
      expect(find.text('Párrafo'), findsWidgets);

      await tester.enterText(field('Título del bloque'), ' Después ');
      await tester.enterText(field('Texto'), ' Texto nuevo ');
      await done(tester);

      expect(find.text('Después'), findsOneWidget);
      expect(find.text('Párrafo · Texto nuevo'), findsOneWidget);

      await done(tester);
      await done(tester);

      final block = result!.pages.single.blocks.single;
      expect(block.kind, ReadingBlockKind.paragraph);
      expect(block.title, 'Después');
      expect(block.body, 'Texto nuevo');
    });

    testWidgets('un bloque sin título se nombra por su tipo', (tester) async {
      await open(
        tester,
        readingOf([
          page('A', const [
            ReadingBlock.bullets(title: '', items: ['uno']),
          ]),
        ]),
      );

      await tap(tester, find.text('A'));

      expect(find.text('Lista de puntos'), findsOneWidget);
      expect(find.text('Lista de puntos · 1 punto'), findsOneWidget);
    });

    testWidgets('añadir pasos numerados descarta los que quedan vacíos', (
      tester,
    ) async {
      await open(tester, readingOf([page('A', const [])]));

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Añadir el primer bloque'));

      // El menú explica cada tipo antes de elegir.
      expect(find.text('¿Qué quieres añadir?'), findsOneWidget);
      expect(find.text('Pasos que hay que seguir en orden'), findsOneWidget);
      expect(
        find.text('Un fragmento de Python con su explicación'),
        findsOneWidget,
      );

      await tap(tester, find.text('Pasos numerados'));
      expect(find.text('Nuevo bloque'), findsOneWidget);
      expect(find.text('Pasos'), findsOneWidget);

      await tap(tester, find.text('Añadir paso'));
      await tap(tester, find.text('Añadir paso'));
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);

      final items = find.descendant(
        of: find
            .ancestor(of: find.text('1.'), matching: find.byType(Column))
            .first,
        matching: find.byType(TextField),
      );
      await tester.enterText(items.first, ' Abrir Python ');
      await tester.pumpAndSettle();
      await done(tester);

      expect(find.text('Pasos numerados · 1 punto'), findsOneWidget);

      await done(tester);
      await done(tester);

      final block = result!.pages.single.blocks.single;
      expect(block.kind, ReadingBlockKind.steps);
      expect(block.items, ['Abrir Python']);
    });

    testWidgets('un bloque de código guarda el código y lo que hace', (
      tester,
    ) async {
      await open(tester, readingOf([page('A', const [])]));

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Añadir el primer bloque'));
      await tap(tester, find.text('Código').last);

      // En un bloque de código nuevo no se pide texto: sobra.
      expect(find.text('Texto'), findsNothing);
      await tester.enterText(field('Código'), 'print("hola")');
      await done(tester);

      // Sin explicación, la lista dice que es un fragmento de código.
      expect(find.text('Código · Fragmento de código'), findsOneWidget);

      await tap(tester, find.text('Código').first);
      await tester.enterText(
        field('Qué hace este código, en palabras'),
        'Saluda por pantalla.',
      );
      await done(tester);
      expect(find.text('Código · Saluda por pantalla.'), findsOneWidget);

      await done(tester);
      await done(tester);

      final block = result!.pages.single.blocks.single;
      expect(block.kind, ReadingBlockKind.code);
      expect(block.code, 'print("hola")');
      expect(block.codeCaption, 'Saluda por pantalla.');
    });

    testWidgets('cerrar el menú de tipos no añade ningún bloque', (
      tester,
    ) async {
      await open(
        tester,
        readingOf([
          page('A', const [ReadingBlock.paragraph(title: 'Uno', body: 'x')]),
        ]),
      );

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Añadir bloque'));
      expect(find.text('¿Qué quieres añadir?'), findsOneWidget);

      // Se toca fuera del menú.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué quieres añadir?'), findsNothing);
      expect(find.text('Nuevo bloque'), findsNothing);
      await done(tester);
      await done(tester);
      expect(result!.pages.single.blocks, hasLength(1));
    });

    testWidgets('salir de un bloque nuevo sin «Listo» no lo añade', (
      tester,
    ) async {
      await open(tester, readingOf([page('A', const [])]));

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Añadir el primer bloque'));
      await tap(tester, find.text('Párrafo'));
      expect(find.text('Nuevo bloque'), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(
        find.text('Esta página todavía no tiene contenido.'),
        findsOneWidget,
      );
    });

    testWidgets('los bloques se reordenan y se borran con confirmación', (
      tester,
    ) async {
      await open(
        tester,
        readingOf([
          page('A', const [
            ReadingBlock.paragraph(title: 'Uno', body: 'x'),
            ReadingBlock.callout(title: 'Dos', body: 'y'),
            ReadingBlock.steps(title: 'Tres', items: ['a']),
          ]),
        ]),
      );

      await tap(tester, find.text('A'));
      await tap(tester, find.byTooltip('Bajar Uno'));
      await tap(tester, find.byTooltip('Subir Tres'));
      // Ahora: Dos, Tres, Uno.

      await tap(tester, find.byTooltip('Borrar Dos'));
      expect(find.text('¿Borrar este bloque?'), findsOneWidget);
      await tap(tester, find.text('Cancelar'));
      expect(find.text('Dos'), findsOneWidget);

      await tap(tester, find.byTooltip('Borrar Dos'));
      await confirm(tester);

      await done(tester);
      await done(tester);

      expect(result!.pages.single.blocks.map((b) => b.title), ['Tres', 'Uno']);
    });

    testWidgets('quitar un punto de una lista lo quita del bloque', (
      tester,
    ) async {
      await open(
        tester,
        readingOf([
          page('A', const [
            ReadingBlock.bullets(title: 'Lista', items: ['uno', 'dos']),
          ]),
        ]),
      );

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Lista'));
      expect(find.text('•'), findsNWidgets(2));

      await tap(tester, find.byTooltip('Quitar').first);
      expect(find.text('•'), findsOneWidget);
      await done(tester);
      await done(tester);
      await done(tester);

      expect(result!.pages.single.blocks.single.items, ['dos']);
    });

    testWidgets('la intención elegida en un recuadro se conserva', (
      tester,
    ) async {
      await open(
        tester,
        readingOf([
          page('A', const [
            ReadingBlock.callout(title: 'Ojo', body: 'Cuidado con esto.'),
          ]),
        ]),
      );

      await tap(tester, find.text('A'));
      await tap(tester, find.text('Ojo'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Error frecuente'));
      await done(tester);
      await done(tester);
      await done(tester);

      final block = result!.pages.single.blocks.single;
      expect(block.kind, ReadingBlockKind.callout);
      expect(block.tone, CalloutTone.danger);
      expect(block.body, 'Cuidado con esto.');
    });
  });
}
