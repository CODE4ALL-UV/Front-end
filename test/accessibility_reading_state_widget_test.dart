import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Evita MissingPluginException cuando las pruebas invocan stop() en flutter_tts.
  // Estas pruebas verifican el estado, no la reproducción de audio real.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (MethodCall call) async => 1,
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  group('ScreenContentExtractor Tests', () {
    testWidgets(
      'Extrae texto normal, texto enriquecido y etiquetas de TextField',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Título de pantalla')),
              body: Column(
                key: const ValueKey('content-root'),
                children: [
                  const Text('  Hola   mundo  '),
                  const Text.rich(
                    TextSpan(
                      text: 'Texto ',
                      children: [TextSpan(text: 'enriquecido')],
                    ),
                  ),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Escribe tu nombre',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final context = tester.element(
          find.byKey(const ValueKey('content-root')),
        );
        final result = ScreenContentExtractor.extractFromContext(context);

        expect(result, contains('Título de pantalla'));
        expect(result, contains('Hola mundo'));
        expect(result, contains('Texto enriquecido'));
        expect(result, contains('Nombre'));
        expect(result, contains('Escribe tu nombre'));
        expect(RegExp(r'\s{2,}').hasMatch(result), isFalse);
      },
    );

    testWidgets('Limita el texto extraído a maxLength caracteres', (
      WidgetTester tester,
    ) async {
      final longText = 'a' * (ScreenContentExtractor.maxLength + 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                key: const ValueKey('content-root'),
                children: [Text(longText)],
              ),
            ),
          ),
        ),
      );

      final context = tester.element(
        find.byKey(const ValueKey('content-root')),
      );
      final result = ScreenContentExtractor.extractFromContext(context);

      expect(result.length, ScreenContentExtractor.maxLength);
      expect(result, 'a' * ScreenContentExtractor.maxLength);
    });

    testWidgets('Devuelve una cadena vacía cuando la pantalla no tiene texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: const SizedBox(key: ValueKey('content-root'))),
        ),
      );

      final context = tester.element(
        find.byKey(const ValueKey('content-root')),
      );

      expect(ScreenContentExtractor.extractFromContext(context), isEmpty);
    });
  });

  group('AccessibilityReadingState Tests', () {
    late AccessibilityReadingState state;

    setUp(() {
      state = AccessibilityReadingState();
    });

    tearDown(() {
      state.dispose();
    });

    test('Inicia sin texto y en estado idle', () {
      expect(state.currentText.value, isNull);
      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });

    test('clearHighlight devuelve el estado a idle', () {
      state.currentText.value = 'Texto de prueba';
      state.status.value = ReadingStatus.speaking;
      state.isHighlighting.value = true;

      state.clearHighlight();

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
      // clearHighlight restablece el estado de lectura, pero conserva el texto.
      expect(state.currentText.value, 'Texto de prueba');
    });

    test(
      'pause, resume y togglePause no hacen nada cuando está idle',
      () async {
        await state.pause();
        await state.resume();
        await state.togglePause();

        expect(state.status.value, ReadingStatus.idle);
        expect(state.isHighlighting.value, isFalse);
        expect(state.currentText.value, isNull);
      },
    );

    test('pause cambia de speaking a paused', () async {
      state.currentText.value = 'Texto de prueba';
      state.status.value = ReadingStatus.speaking;
      state.isHighlighting.value = true;

      await state.pause();

      expect(state.status.value, ReadingStatus.paused);
      expect(state.isHighlighting.value, isTrue);
      expect(state.currentText.value, 'Texto de prueba');
    });

    test('resume sin texto pendiente vuelve a idle', () async {
      state.status.value = ReadingStatus.paused;
      state.isHighlighting.value = true;
      state.currentText.value = null;

      await state.resume();

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });

    test('stop restablece el estado a idle', () async {
      state.currentText.value = 'Texto de prueba';
      state.status.value = ReadingStatus.speaking;
      state.isHighlighting.value = true;

      await state.stop();

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });
  });
}
