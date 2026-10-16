import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    // El test valida los estados de la interfaz, no la salida de audio real.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (MethodCall call) async => 1);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  setUp(() {
    AccessibilityTextScaleController.global.reset();
    accessibilityReadingState.clearHighlight();
    accessibilityReadingState.currentText.value = null;
  });

  tearDown(() {
    AccessibilityTextScaleController.global.reset();
    accessibilityReadingState.clearHighlight();
    accessibilityReadingState.currentText.value = null;
  });

  Widget buildTestApp({String? spokenText}) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: <ThemeExtension<dynamic>>[_TestModuleCardThemeColors()],
      ),
      home: Scaffold(body: AccessibilityToolbar(spokenText: spokenText)),
    );
  }

  group('AccessibilityToolbar Tests', () {
    testWidgets('Muestra los controles de lectura y tamaño de texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Escuchar'), findsOneWidget);
      expect(find.byTooltip('Reducir el tamaño del texto'), findsOneWidget);
      expect(find.byTooltip('Aumentar el tamaño del texto'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Aumenta el tamaño de texto al pulsar el control', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());

      final initialScale = AccessibilityTextScaleController.global.scale;
      await tester.tap(find.byTooltip('Aumentar el tamaño del texto'));
      await tester.pump();

      final updatedScale = AccessibilityTextScaleController.global.scale;
      expect(updatedScale, greaterThan(initialScale));
      expect(find.text('${(updatedScale * 100).round()}%'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Reduce el tamaño de texto al pulsar el control', (
      WidgetTester tester,
    ) async {
      AccessibilityTextScaleController.global.setScale(1.2);
      await tester.pumpWidget(buildTestApp());

      final initialScale = AccessibilityTextScaleController.global.scale;
      await tester.tap(find.byTooltip('Reducir el tamaño del texto'));
      await tester.pump();

      final updatedScale = AccessibilityTextScaleController.global.scale;
      expect(updatedScale, lessThan(initialScale));
      expect(find.text('${(updatedScale * 100).round()}%'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Expone el control para escuchar cuando la lectura está idle', (
      WidgetTester tester,
    ) async {
      accessibilityReadingState.status.value = ReadingStatus.idle;
      await tester.pumpWidget(buildTestApp(spokenText: 'Texto de prueba'));

      expect(find.text('Escuchar'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Escuchar esta pantalla en voz alta'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('En una pantalla sin texto avisa de que no hay nada que leer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      tester.takeAnnouncements();

      await tester.tap(find.text('Escuchar'));
      await tester.pump();

      // Los botones de la propia franja no cuentan como texto de la pantalla.
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('Esta pantalla no tiene texto que leer.'),
      );
      expect(accessibilityReadingState.status.value, ReadingStatus.idle);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Escuchar lee la pantalla sin los textos de la franja', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(
            extensions: <ThemeExtension<dynamic>>[_TestModuleCardThemeColors()],
          ),
          home: const Scaffold(
            body: Column(
              children: [AccessibilityToolbar(), Text('Hola mundo')],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Escuchar'));
      await tester.pump();

      expect(accessibilityReadingState.currentText.value, 'Hola mundo');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Cambia a Pausar cuando la lectura está hablando', (
      WidgetTester tester,
    ) async {
      accessibilityReadingState.currentText.value = 'Texto de prueba';
      accessibilityReadingState.status.value = ReadingStatus.speaking;
      accessibilityReadingState.isHighlighting.value = true;

      await tester.pumpWidget(buildTestApp());

      expect(find.text('Pausar'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pausar la lectura en voz alta'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Pulsar Pausar cambia el estado speaking a paused', (
      WidgetTester tester,
    ) async {
      accessibilityReadingState.currentText.value = 'Texto de prueba';
      accessibilityReadingState.status.value = ReadingStatus.speaking;
      accessibilityReadingState.isHighlighting.value = true;

      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Pausar'));
      await tester.pump();
      await tester.pump();

      expect(accessibilityReadingState.status.value, ReadingStatus.paused);
      expect(find.text('Reanudar'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Muestra Reanudar cuando la lectura está pausada', (
      WidgetTester tester,
    ) async {
      accessibilityReadingState.currentText.value = 'Texto de prueba';
      accessibilityReadingState.status.value = ReadingStatus.paused;
      accessibilityReadingState.isHighlighting.value = true;

      await tester.pumpWidget(buildTestApp());

      expect(find.text('Reanudar'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Reanudar la lectura en voz alta'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Proporciona únicamente los colores que usa la barra en esta prueba.
/// Los demás miembros de la ThemeExtension no son necesarios para construirla.
class _TestModuleCardThemeColors implements ModuleTheme {
  @override
  Color get headerBackground => const Color(0xFF5E35B1);

  @override
  Color get headerForeground => Colors.white;

  @override
  Type get type => ModuleTheme;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
