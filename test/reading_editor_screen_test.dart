import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/course_section_edits.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_test/flutter_test.dart';

CourseSection _section() {
  return CourseContentStore.instance.section(1, 1) ??
      PythonCourseCatalog.section(1, 1)!;
}

SectionReading _reading({
  String title = 'Lectura de prueba',
  String intro = 'Introducción de prueba',
  List<ReadingPage>? pages,
}) {
  return SectionReading(
    title: title,
    intro: intro,
    pages:
        pages ??
        const [
          ReadingPage(
            title: 'Página inicial',
            summary: 'Resumen inicial',
            blocks: [
              ReadingBlock.paragraph(
                title: 'Primer párrafo',
                body: 'Contenido del primer párrafo.',
              ),
            ],
          ),
        ],
  );
}

Widget _buildApp({required CourseSection section, SectionReading? reading}) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      body: ReadingEditorScreen(reading: reading, section: section),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CourseSection section;

  setUp(() {
    section = _section();
  });

  group('ReadingEditorScreen', () {
    testWidgets('muestra el estado vacío cuando no hay lectura', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(section: section));
      await tester.pumpAndSettle();

      expect(find.text('Lectura'), findsOneWidget);
      expect(find.text('Crear la lectura'), findsOneWidget);
      expect(
        find.textContaining('Esta sección no tiene lectura'),
        findsOneWidget,
      );
    });

    testWidgets('crea una lectura con una primera página', (tester) async {
      await tester.pumpWidget(_buildApp(section: section));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear la lectura'));
      await tester.pumpAndSettle();

      expect(find.text('Título de la lectura'), findsOneWidget);
      expect(find.text('Introducción'), findsOneWidget);
      expect(find.text('Páginas'), findsOneWidget);
      expect(find.text('Página 1'), findsOneWidget);
      expect(find.text('Añadir página'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        section.title,
      );
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        section.summary,
      );
    });

    testWidgets('muestra los datos de una lectura existente', (tester) async {
      final reading = _reading();

      await tester.pumpWidget(_buildApp(section: section, reading: reading));
      await tester.pumpAndSettle();

      expect(find.text('Título de la lectura'), findsOneWidget);
      expect(find.text('Introducción'), findsOneWidget);
      expect(find.text('Página inicial'), findsOneWidget);
      expect(find.text('1 bloques'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        'Lectura de prueba',
      );
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        'Introducción de prueba',
      );
    });

    testWidgets('permite añadir una página', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildApp(section: _section(), reading: _reading()),
      );
      await tester.pumpAndSettle();

      final addPageButton = find.text('Añadir página');

      await tester.ensureVisible(addPageButton);
      await tester.pumpAndSettle();
      await tester.tap(addPageButton);
      await tester.pumpAndSettle();

      expect(find.text('Página inicial'), findsOneWidget);
      expect(find.text('Página 2'), findsOneWidget);
    });

    testWidgets('abre el editor de una página', (tester) async {
      await tester.pumpWidget(_buildApp(section: section, reading: _reading()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página inicial'));
      await tester.pumpAndSettle();

      expect(find.text('Página 1'), findsOneWidget);
      expect(find.text('Título de la página'), findsOneWidget);
      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Bloques'), findsOneWidget);
      expect(find.text('Primer párrafo'), findsOneWidget);
    });

    testWidgets('muestra el estado vacío de una página sin bloques', (
      tester,
    ) async {
      final reading = _reading(
        pages: const [
          ReadingPage(
            title: 'Página vacía',
            summary: 'Todavía sin contenido',
            blocks: [],
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(section: section, reading: reading));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página vacía'));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta página todavía no tiene contenido.'),
        findsOneWidget,
      );
      expect(find.text('Añadir el primer bloque'), findsOneWidget);
    });

    testWidgets('permite abrir el selector de tipos de bloque', (tester) async {
      await tester.pumpWidget(_buildApp(section: section, reading: _reading()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página inicial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primer párrafo'));
      await tester.pumpAndSettle();

      expect(find.text('Tipo de bloque'), findsOneWidget);
      expect(find.text('Título del bloque'), findsOneWidget);
      expect(find.text('Texto'), findsOneWidget);
    });

    testWidgets('permite cambiar el tipo de bloque a código', (tester) async {
      await tester.pumpWidget(_buildApp(section: section, reading: _reading()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página inicial'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Primer párrafo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ReadingBlockKind.code.label).last);
      await tester.pumpAndSettle();

      expect(find.text('Código'), findsWidgets);
      expect(find.text('Qué hace este código, en palabras'), findsOneWidget);
    });

    testWidgets('permite editar un bloque de lista y añadir un punto', (
      tester,
    ) async {
      final reading = _reading(
        pages: const [
          ReadingPage(
            title: 'Página de lista',
            summary: '',
            blocks: [
              ReadingBlock.bullets(
                title: 'Lista de prueba',
                body: 'Introducción de la lista',
                items: ['Primer elemento'],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(section: section, reading: reading));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página de lista'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lista de prueba'));
      await tester.pumpAndSettle();

      expect(find.text('Puntos'), findsOneWidget);
      expect(find.text('Añadir punto'), findsOneWidget);

      final addPointButton = find.text('Añadir punto');

      await tester.ensureVisible(addPointButton);
      await tester.pumpAndSettle();
      await tester.tap(addPointButton);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      await tester.pumpAndSettle();

      expect(find.byType(TextField).evaluate().length, greaterThan(0));
    });

    testWidgets('muestra las opciones de intención de un recuadro', (
      tester,
    ) async {
      final reading = _reading(
        pages: const [
          ReadingPage(
            title: 'Página de avisos',
            summary: '',
            blocks: [
              ReadingBlock.callout(
                title: 'Aviso de prueba',
                body: 'Contenido destacado.',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(section: section, reading: reading));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página de avisos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aviso de prueba'));
      await tester.pumpAndSettle();

      expect(find.text('Intención del recuadro'), findsOneWidget);

      for (final tone in CalloutTone.values) {
        expect(find.text(tone.label), findsOneWidget);
      }
    });

    testWidgets('permite cambiar la intención del recuadro', (tester) async {
      final reading = _reading(
        pages: const [
          ReadingPage(
            title: 'Página de avisos',
            summary: '',
            blocks: [
              ReadingBlock.callout(
                title: 'Aviso de prueba',
                body: 'Contenido destacado.',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(_buildApp(section: section, reading: reading));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Página de avisos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aviso de prueba'));
      await tester.pumpAndSettle();

      final tone = CalloutTone.values.last;

      final toneOption = find.ancestor(
        of: find.text(tone.label).first,
        matching: find.byType(ChoiceChip),
      );

      await tester.ensureVisible(toneOption);
      await tester.pumpAndSettle();
      await tester.tap(toneOption);
      await tester.pumpAndSettle();

      expect(tester.widget<ChoiceChip>(toneOption).selected, isTrue);
    });
  });
}
