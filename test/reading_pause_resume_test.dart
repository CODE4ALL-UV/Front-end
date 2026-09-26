import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';

/// Lo que de verdad hay que comprobar de pausar la voz: que al reanudar siga
/// por donde iba y no vuelva a empezar por el principio. Un estudiante que
/// pausa a mitad de una lección larga y tiene que oírla entera otra vez deja
/// de usar el botón.
///
/// El motor de voz no existe en un test, así que se finge su canal y se apunta
/// con qué texto se le manda hablar cada vez. Eso basta: lo que se quiere
/// saber es qué trozo se pide, no cómo suena.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  final spoken = <String>[];

  /// Una pantalla vacía, solo para tener un contexto con Directionality, que
  /// es lo que necesita el aviso a los lectores de pantalla.
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.shrink(),
      ),
    );
    return tester.element(find.byType(SizedBox));
  }

  /// Simula al motor diciendo por qué carácter va, que es lo que el estado
  /// usa para saber dónde retomar.
  Future<void> reportProgress(String text, int start) async {
    await TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .handlePlatformMessage(
          'flutter_tts',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('speak.onProgress', {
              'text': text,
              'start': '$start',
              'end': '${start + 1}',
              'word': 'x',
            }),
          ),
          (_) {},
        );
  }

  setUp(() {
    spoken.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'speak') {
            spoken.add(call.arguments.toString());
          }
          return 1;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('pausar y reanudar la lectura', () {
    testWidgets('al reanudar sigue donde se quedó, no desde el principio', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      const texto = 'Primera frase. Segunda frase. Tercera frase.';
      final cortePorLaSegunda = texto.indexOf('Segunda');

      final context = await pumpHost(tester);
      await state.read(texto, context);
      expect(state.status.value, ReadingStatus.speaking);
      expect(spoken.single, texto, reason: 'la primera vez se lee entero');

      await reportProgress(texto, cortePorLaSegunda);
      await state.pause();
      expect(state.status.value, ReadingStatus.paused);

      await state.resume();

      expect(state.status.value, ReadingStatus.speaking);
      expect(
        spoken.last,
        texto.substring(cortePorLaSegunda),
        reason: 'debe retomar por «Segunda», no repetir la primera frase',
      );
    });

    testWidgets('pausar no cuenta como terminar', (tester) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      final context = await pumpHost(tester);
      await state.read('Una frase cualquiera.', context);
      await state.pause();

      // Callar el motor dispara el mismo aviso que una cancelación. Si eso se
      // contara como final, se perdería el punto donde iba y el botón volvería
      // a «escuchar» en vez de a «reanudar».
      expect(state.status.value, ReadingStatus.paused);
      expect(state.isHighlighting.value, isTrue);
    });

    testWidgets('parar sí termina, y deja el botón en «escuchar»', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      final context = await pumpHost(tester);
      await state.read('Una frase cualquiera.', context);
      await state.stop();

      expect(state.status.value, ReadingStatus.idle);
      expect(state.isHighlighting.value, isFalse);
    });

    testWidgets('reanudar sin haber pausado no hace nada', (tester) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      await state.resume();

      expect(state.status.value, ReadingStatus.idle);
      expect(spoken, isEmpty);
    });

    testWidgets('pausar dos veces seguidas no pierde el punto', (tester) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      const texto = 'Primera frase. Segunda frase. Tercera frase.';
      final corte = texto.indexOf('Segunda');

      final context = await pumpHost(tester);
      await state.read(texto, context);
      await reportProgress(texto, corte);

      await state.pause();
      await state.pause(); // la segunda no debe tocar nada

      await state.resume();

      expect(spoken.last, texto.substring(corte));
    });

    testWidgets('empezar una lectura nueva olvida la pausa anterior', (
      tester,
    ) async {
      final state = AccessibilityReadingState();
      addTearDown(state.dispose);

      const primera = 'Primera frase. Segunda frase.';
      const segunda = 'Otro texto distinto.';

      final context = await pumpHost(tester);
      await state.read(primera, context);
      await reportProgress(primera, primera.indexOf('Segunda'));
      await state.pause();

      await state.read(segunda, context);

      expect(state.status.value, ReadingStatus.speaking);
      expect(
        spoken.last,
        segunda,
        reason: 'la pantalla nueva se lee entera, no a medias',
      );
    });
  });
}
