import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_video_screen.dart';
import 'package:flutter_test/flutter_test.dart';

// Si SectionVideoScreen está en otra ruta, ajusta el import anterior
// a la ubicación real del archivo.

CourseModule _module() {
  // Se utiliza el catálogo real para evitar construir modelos artificiales.
  return PythonCourseCatalog.moduleByNumber(1)!;
}

CourseSection _section() {
  return CourseContentStore.instance.section(1, 1) ??
      PythonCourseCatalog.section(1, 1)!;
}

Widget _buildApp({
  required CourseModule module,
  required CourseSection section,
  double width = 800,
}) {
  final theme = ThemeData.light().copyWith(
    extensions: const <ThemeExtension<dynamic>>[
      MessageTheme(
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
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: SectionVideoScreen(module: module, section: section),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CourseModule module;
  late CourseSection section;

  setUp(() {
    module = _module();
    section = _section();
  });

  group('SectionVideoScreen', () {
    testWidgets('muestra la información inicial de la actividad', (
      tester,
    ) async {
      // Evita que las animaciones de widgets externos prolonguen la prueba.
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();

      expect(find.text('Subtítulos'), findsOneWidget);
      expect(find.text('Marcar como visto'), findsOneWidget);
      expect(find.text('Copiar enlace'), findsOneWidget);
      expect(find.text('Practicar el alfabeto con la cámara'), findsOneWidget);
    });

    testWidgets('muestra la transcripción cuando existe', (tester) async {
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();

      if (section.videos.isNotEmpty &&
          section.videos.first.transcript.isNotEmpty) {
        expect(find.text('Transcripción completa'), findsOneWidget);
        expect(find.text(section.videos.first.transcript), findsOneWidget);
      } else {
        expect(find.text('Transcripción completa'), findsNothing);
      }
    });

    testWidgets('muestra los controles de frases si hay transcripción', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();

      final transcript = section.videos.first.transcript;

      if (transcript.trim().isEmpty) {
        expect(find.textContaining('Frase '), findsNothing);
        return;
      }

      expect(find.textContaining('Frase 1 de '), findsOneWidget);
      expect(find.byTooltip('Frase anterior'), findsOneWidget);
      expect(find.byTooltip('Reproducir los subtítulos'), findsOneWidget);
      expect(find.byTooltip('Frase siguiente'), findsOneWidget);
    });

    testWidgets('permite avanzar a la siguiente frase', (tester) async {
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();
      final transcript = section.videos.first.transcript;
      final phrases = transcript
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .split(RegExp(r'(?<=[.;:])\s+'))
          .where((phrase) => phrase.trim().isNotEmpty)
          .toList();
      if (phrases.length < 2) {
        expect(find.textContaining('Frase '), findsNothing);
        return;
      }
      expect(find.text('Frase 1 de ${phrases.length}'), findsOneWidget);
      final nextButton = find.byTooltip('Frase siguiente');
      await tester.ensureVisible(nextButton);
      await tester.pump();
      await tester.tap(nextButton);
      await tester.pump();
      expect(find.text('Frase 2 de ${phrases.length}'), findsOneWidget);
      expect(find.text(phrases[1]), findsOneWidget);
    });
    testWidgets('permite pausar y reanudar la transcripción', (tester) async {
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();
      if (section.videos.first.transcript.trim().isEmpty) {
        expect(find.byTooltip('Reproducir los subtítulos'), findsNothing);
        return;
      }
      final playButton = find.byTooltip('Reproducir los subtítulos');
      await tester.ensureVisible(playButton);
      await tester.pump();
      await tester.tap(playButton);
      await tester.pump();
      final pauseButton = find.byTooltip('Pausar los subtítulos');
      expect(pauseButton, findsOneWidget);
      await tester.ensureVisible(pauseButton);
      await tester.pump();
      await tester.tap(pauseButton);
      await tester.pump();
      expect(find.byTooltip('Reproducir los subtítulos'), findsOneWidget);
    });

    testWidgets('muestra el selector si hay varios videos', (tester) async {
      await tester.pumpWidget(_buildApp(module: module, section: section));
      await tester.pump();

      if (section.videos.length > 1) {
        expect(
          find.text('${section.videos.length} videos en esta sección'),
          findsOneWidget,
        );
      } else {
        expect(find.textContaining('videos en esta sección'), findsNothing);
      }
    });

    testWidgets('se adapta a una pantalla estrecha', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildApp(module: module, section: section, width: 390),
      );
      await tester.pump();

      expect(find.text('Subtítulos'), findsOneWidget);
      expect(find.text('Marcar como visto'), findsOneWidget);
    });
  });
}
