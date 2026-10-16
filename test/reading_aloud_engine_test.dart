import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';

/// La lectura en voz alta depende de lo que el motor de voz del sistema le
/// va avisando: que terminó, que lo cortaron, que falló. Si alguno de esos
/// avisos se pierde, el botón se queda en «Pausar» para siempre y quien no ve
/// la pantalla no sabe si la lectura sigue o no.
///
/// El motor no existe en una prueba, así que se finge su canal: se apunta lo
/// que se le pide, se le puede hacer fallar a voluntad y se simulan sus
/// avisos como si llegaran del sistema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];

  /// Métodos del motor que fallarán en la prueba en curso.
  final failing = <String>{};

  List<String> spoken() => [
    for (final call in calls)
      if (call.method == 'speak') call.arguments.toString(),
  ];

  List<double> rates() => [
    for (final call in calls)
      if (call.method == 'setSpeechRate') (call.arguments as num).toDouble(),
  ];

  /// Un aviso del motor, tal como llega del sistema.
  Future<void> engineSays(String method, [Object? arguments]) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter_tts',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, arguments),
          ),
          (_) {},
        );
  }

  Future<void> progressAt(String text, int start) => engineSays(
    'speak.onProgress',
    {'text': text, 'start': '$start', 'end': '${start + 1}', 'word': 'x'},
  );

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(),
      ),
    );
    return tester.element(find.byType(SizedBox));
  }

  setUp(() {
    calls.clear();
    failing.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (failing.contains(call.method)) {
            throw PlatformException(code: 'tts', message: 'sin motor');
          }
          return 1;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('avisos del motor', () {
    testWidgets('al terminar de hablar el botón vuelve a «Escuchar»', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Una frase corta.', context);
      expect(state.status.value, ReadingStatus.speaking);

      await engineSays('speak.onComplete');

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });

    testWidgets('si otro corta la voz (no una pausa), cuenta como terminar', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Otra frase.', context);
      await engineSays('speak.onCancel');

      expect(state.status.value, ReadingStatus.idle);
    });

    testWidgets('un error del motor no deja la lectura colgada', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Una frase.', context);
      await engineSays('speak.onError', 'error de audio');

      expect(state.status.value, ReadingStatus.idle);
    });

    testWidgets('después de terminar, una lectura nueva empieza desde el '
        'principio', (tester) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      const texto = 'Primera frase. Segunda frase.';
      await state.read(texto, context);
      await progressAt(texto, texto.indexOf('Segunda'));
      await engineSays('speak.onComplete');

      await state.read(texto, context);

      expect(spoken().last, texto);
    });
  });

  group('pausar y reanudar con un solo botón', () {
    testWidgets('togglePause pausa lo que suena y reanuda lo pausado', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      const texto = 'Uno dos tres. Cuatro cinco seis.';
      await state.read(texto, context);
      await progressAt(texto, texto.indexOf('Cuatro'));

      await state.togglePause();
      expect(state.status.value, ReadingStatus.paused);

      await state.togglePause();
      expect(state.status.value, ReadingStatus.speaking);
      expect(spoken().last, texto.substring(texto.indexOf('Cuatro')));
    });

    testWidgets('si la pausa llegó al final, reanudar da la lectura por '
        'terminada', (tester) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      const texto = 'Solo esto.';
      await state.read(texto, context);
      await progressAt(texto, texto.length);
      await state.pause();
      final speaksBefore = spoken().length;

      await state.resume();

      // No hay nada que leer: no se manda hablar en vacío y el botón vuelve
      // a ofrecer «Escuchar».
      expect(spoken().length, speaksBefore);
      expect(state.status.value, ReadingStatus.idle);
    });
  });

  group('cuando el motor falla', () {
    testWidgets('si no se puede hablar, la lectura vuelve a reposo', (
      tester,
    ) async {
      failing.add('speak');
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Texto que no sonará.', context);

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });

    testWidgets('un fallo al configurar el idioma no impide leer', (
      tester,
    ) async {
      failing.add('setLanguage');
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Hola.', context);

      expect(spoken(), ['Hola.']);
      expect(state.status.value, ReadingStatus.speaking);
    });

    testWidgets('si el motor no se deja callar, la pausa se respeta igual', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await state.read('Una frase larga.', context);
      failing.add('stop');

      await state.pause();

      expect(state.status.value, ReadingStatus.paused);
    });
  });

  group('velocidad de la voz', () {
    // Las preferencias se guardan en el almacén seguro; sin este almacén en
    // memoria, la escritura esperaría a un canal nativo que no existe.
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    tearDown(() async {
      await LearningPreferences.instance.setPace(SpeechPace.medium);
      await LearningPreferences.instance.setClearSpeech(false);
    });

    testWidgets('cada lectura usa la velocidad elegida en ese momento', (
      tester,
    ) async {
      final prefs = LearningPreferences.instance;
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);
      final context = await pumpHost(tester);

      await prefs.setPace(SpeechPace.slow);
      await state.read('Primera.', context);
      expect(rates().last, SpeechPace.slow.rate);

      // Cambiarla en el panel se nota en la siguiente lectura, sin reiniciar.
      await prefs.setPace(SpeechPace.fast);
      await prefs.setClearSpeech(true);
      await state.read('Segunda.', context);
      expect(rates().last, closeTo(SpeechPace.fast.rate * 0.7, 0.0001));
    });
  });
}
