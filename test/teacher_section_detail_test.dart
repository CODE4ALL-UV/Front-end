import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/activity_theme.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';

// TeacherField dibuja la etiqueta fuera de la decoración del TextField; por eso
// no se puede localizar de forma fiable usando decoration.labelText. Los tres
// campos de identidad se construyen en orden: título, título corto y descripción.
Finder _field(String label) {
  final index = switch (label) {
    'Título de la sección' => 0,
    'Título corto' => 1,
    'Descripción' => 2,
    _ => throw ArgumentError.value(label, 'label', 'Campo desconocido'),
  };
  return find.byType(TextField).at(index);
}

CourseSection _initialSection() {
  return CourseContentStore.instance.section(1, 1) ??
      PythonCourseCatalog.section(1, 1)!;
}

Widget _buildApp() {
  final theme = ThemeData.light().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      const ActivityTheme(
        readingBackground: Color(0xFFE3E8FF),
        readingForeground: Color(0xFF202060),
        nuggetBackground: Color(0xFFF0F4C3),
        nuggetForeground: Color(0xFF33691E),
        exampleBackground: Color(0xFFFFE0B2),
        exampleForeground: Color(0xFF8D3B00),
        exerciseBackground: Color(0xFFE1BEE7),
        exerciseForeground: Color(0xFF4A148C),
        videoBackground: Color(0xFFF3E5F5),
        videoForeground: Color(0xFF880E4F),
        quizBackground: Color(0xFFD7CCC8),
        quizForeground: Color(0xFF4E342E),
        labBackground: Color(0xFFB2DFDB),
        labForeground: Color(0xFF004D40),
        finalEvaluationBackground: Color(0xFFFFCCBC),
        finalEvaluationForeground: Color(0xFFBF360C),
      ),
      const MessageTheme(
        infoBackground: Color(0xFFE3F2FD),
        infoForeground: Color(0xFF0D47A1),
        successBackground: Color(0xFFE8F5E9),
        successForeground: Color(0xFF1B5E20),
        warningBackground: Color(0xFFFFF8E1),
        warningForeground: Color(0xFF8D4B00),
        dangerBackground: Color(0xFFFFEBEE),
        dangerForeground: Color(0xFFB71C1C),
      ),
    ],
  );

  return MaterialApp(
    home: Theme(
      data: theme,
      child: const Scaffold(
        body: TeacherSectionDetail(moduleNumber: 1, sectionNumber: 1),
      ),
    ),
  );
}

Future<void> _mount(WidgetTester tester, {int width = 800}) async {
  tester.view.physicalSize = Size(width.toDouble(), 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_buildApp());
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeacherSectionDetail: carga y formulario', () {
    testWidgets(
      'muestra identidad de la sección, actividades y barra de guardado',
      (tester) async {
        await _mount(tester);

        expect(find.text('Módulo 1 · Sección 1'), findsOneWidget);
        expect(_field('Título de la sección'), findsOneWidget);
        expect(_field('Título corto'), findsOneWidget);
        expect(_field('Descripción'), findsOneWidget);
        expect(find.text('Actividades'), findsOneWidget);
        expect(find.text('Lectura'), findsOneWidget);
        expect(find.text('Cápsula de conocimiento'), findsOneWidget);
        expect(find.text('Videos'), findsOneWidget);
        expect(find.text('Quiz'), findsOneWidget);
        expect(find.text('Evaluación final'), findsOneWidget);
        expect(find.text('Ejemplo comentado'), findsOneWidget);
        expect(find.text('Ejercicio'), findsOneWidget);
        expect(find.text('Laboratorio'), findsOneWidget);
        expect(find.text('Sin cambios'), findsOneWidget);
        expect(find.text('Guardar'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets('precarga los campos con el contenido de la sección actual', (
      tester,
    ) async {
      final section = _initialSection();
      await _mount(tester);

      expect(
        tester
            .widget<TextField>(_field('Título de la sección'))
            .controller!
            .text,
        section.title,
      );
      expect(
        tester.widget<TextField>(_field('Título corto')).controller!.text,
        section.shortTitle ?? '',
      );
      expect(
        tester.widget<TextField>(_field('Descripción')).controller!.text,
        section.summary,
      );
    });

    testWidgets(
      'al cambiar el título anuncia cambios pendientes y habilita Guardar',
      (tester) async {
        await _mount(tester);

        final titleField = _field('Título de la sección');
        await tester.ensureVisible(titleField);
        await tester.enterText(titleField, 'Título actualizado para pruebas');
        await tester.pumpAndSettle();

        expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'mantiene el estado sin cambios al volver a escribir el título corto guardado',
      (tester) async {
        final section = _initialSection();
        await _mount(tester);

        final shortTitleField = _field('Título corto');
        await tester.ensureVisible(shortTitleField);
        await tester.enterText(shortTitleField, section.shortTitle ?? '');
        await tester.pumpAndSettle();

        expect(find.text('Sin cambios'), findsOneWidget);
        expect(find.text('Tienes cambios sin guardar'), findsNothing);
      },
    );

    testWidgets(
      'al editar la descripción marca el formulario como modificado',
      (tester) async {
        await _mount(tester);

        final summaryField = _field('Descripción');
        await tester.ensureVisible(summaryField);
        await tester.enterText(
          summaryField,
          'Resumen actualizado desde una prueba.',
        );
        await tester.pumpAndSettle();

        expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
      },
    );

    testWidgets(
      'el interruptor de laboratorio cambia su descripción y habilita guardar',
      (tester) async {
        await _mount(tester);

        final switchFinder = find.byType(SwitchListTile);
        expect(switchFinder, findsOneWidget);
        final before = tester.widget<SwitchListTile>(switchFinder).value;
        await tester.ensureVisible(switchFinder);
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(tester.widget<SwitchListTile>(switchFinder).value, !before);
        // El cambio del interruptor se refleja en el contenido de la tarjeta.
        // _hasChanges también debe comparar hasLaboratory para habilitar Guardar.
        expect(
          find.text(
            before
                ? 'Esta sección no ofrece laboratorio'
                : 'El estudiante puede escribir y ejecutar código',
          ),
          findsOneWidget,
        );
        expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
      },
    );
  });

  group('TeacherSectionDetail: navegación y diseño adaptable', () {
    testWidgets('abre el editor de lectura al tocar la tarjeta Lectura', (
      tester,
    ) async {
      await _mount(tester);
      await _tapVisible(tester, find.text('Lectura').first);

      expect(find.byType(ReadingEditorScreen), findsOneWidget);
    });

    testWidgets(
      'en una pantalla estrecha conserva el acceso a vista previa y guardado',
      (tester) async {
        await _mount(tester, width: 320);

        expect(find.text('Ver como estudiante'), findsOneWidget);
        expect(find.text('Sin cambios'), findsOneWidget);
        expect(find.text('Guardar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
