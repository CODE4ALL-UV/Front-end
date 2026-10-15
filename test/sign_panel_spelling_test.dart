import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_language_panel.dart';

/// El manejador de siempre de `flutter/assets`: lee los archivos que el
/// comando de pruebas empaqueta. Se vuelve a poner al terminar cada prueba
/// que lo cambia, para no dejar a las demás sin fuentes ni imágenes.
Future<ByteData?>? _realAssets(ByteData? message) {
  final folder = Platform.environment['UNIT_TEST_ASSETS'];
  if (folder == null || message == null) return null;
  var key = utf8.decode(message.buffer.asUint8List());
  var file = File('$folder/$key');
  if (!file.existsSync()) {
    // Igual que el original: los assets pueden pedirse con el prefijo del
    // paquete.
    final prefix = 'packages/${Platform.environment['APP_NAME']}/';
    if (!key.startsWith(prefix)) return null;
    key = key.replaceFirst(prefix, '');
    file = File('$folder/$key');
    if (!file.existsSync()) return null;
  }
  final bytes = Uint8List.fromList(file.readAsBytesSync());
  return SynchronousFuture<ByteData?>(bytes.buffer.asByteData());
}

/// Finge un manifiesto de assets con las rutas indicadas.
void _useManifest(List<String> paths, {bool broken = false}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'AssetManifest.bin') {
          if (broken) {
            // Un manifiesto que no es un mapa: no se puede leer.
            return Future.value(
              const StandardMessageCodec().encodeMessage(<Object?>['basura']),
            );
          }
          return Future.value(
            const StandardMessageCodec().encodeMessage(<Object?, Object?>{
              for (final path in paths) path: <Object?>[],
            }),
          );
        }
        // Las imágenes del manifiesto no existen de verdad.
        return Future.value(null);
      });
}

/// El panel de señas deletrea letra a letra lo que dice el subtítulo.
///
/// Se comprueba que siga al subtítulo cuando cambia, que se pare y se reanude
/// con el video, que avise de las letras que llevan movimiento y que, en
/// cuanto se empaqueten fotos o clips de señas reales, se usen en lugar del
/// dibujo sin tocar código. Si esas fotos no cargan, la mano dibujada sigue
/// ahí: el panel nunca se queda en blanco.
void main() {
  final index = SignAssetIndex.instance;

  setUp(index.debugReset);

  tearDown(() {
    index.debugReset();
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', _realAssets);
  });

  Widget panel(String text, {bool playing = true, bool words = true}) =>
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: SignLanguagePanel(
              text: text,
              isPlaying: playing,
              showWordSigns: words,
            ),
          ),
        ),
      );

  double progressOf(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value!;

  group('el deletreo', () {
    testWidgets('al cambiar el subtítulo empieza otra vez desde su inicio', (
      tester,
    ) async {
      await tester.pumpWidget(panel('sol'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('O'), findsOneWidget);

      await tester.pumpWidget(panel('mar'));
      await tester.pump();

      expect(find.text('M'), findsOneWidget);
      expect(find.text('MAR'), findsOneWidget);
      expect(progressOf(tester), closeTo(1 / 3, 0.001));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('en pausa se queda en su letra y al reanudar sigue', (
      tester,
    ) async {
      await tester.pumpWidget(panel('luz', playing: false));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('L'), findsOneWidget);

      await tester.pumpWidget(panel('luz'));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('U'), findsOneWidget);

      // Pausar otra vez detiene el avance justo ahí.
      await tester.pumpWidget(panel('luz', playing: false));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('U'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('al terminar la frase se queda en la última letra', (
      tester,
    ) async {
      await tester.pumpWidget(panel('sí'));
      await tester.pump(const Duration(seconds: 3));

      // La tilde se quita: se deletrea la letra, no el acento.
      expect(find.text('I'), findsOneWidget);
      expect(find.text('SI'), findsOneWidget);
      expect(progressOf(tester), 1.0);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('una letra que lleva movimiento lo avisa', (tester) async {
      await tester.pumpWidget(panel('J', words: false));
      await tester.pump();

      expect(find.text('J'), findsOneWidget);
      expect(find.text('lleva movimiento'), findsOneWidget);

      await tester.pumpWidget(panel('A', words: false));
      await tester.pump();
      expect(find.text('lleva movimiento'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('el espacio entre palabras se ve como un hueco', (
      tester,
    ) async {
      await tester.pumpWidget(panel('a b', words: false));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('␣'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('las señas grabadas', () {
    testWidgets('el índice encuentra las fotos sin importar tildes', (
      tester,
    ) async {
      _useManifest([
        'assets/sign_language/letras/a.png',
        'assets/sign_language/letras/enie.jpg',
        'assets/sign_language/letras/README.md',
        'assets/sign_language/palabras/función.gif',
        'assets/sign_language/palabras/.gif',
        'assets/images/logo.png',
      ]);

      await tester.runAsync(index.ensureLoaded);

      expect(index.isLoaded, isTrue);
      expect(index.hasAnyLetter, isTrue);
      expect(index.hasAnyWord, isTrue);
      expect(index.letterAsset('A'), 'assets/sign_language/letras/a.png');
      expect(index.letterAsset('á'), 'assets/sign_language/letras/a.png');
      expect(index.letterAsset('Ñ'), 'assets/sign_language/letras/enie.jpg');
      expect(
        index.wordAsset('FUNCION'),
        'assets/sign_language/palabras/función.gif',
      );
      // Ni los README ni las imágenes de otras carpetas son señas.
      expect(index.letterAsset('readme'), isNull);
      expect(index.wordAsset('logo'), isNull);
      expect(index.letterAsset('logo'), isNull);
    });

    testWidgets(
      'con fotos empaquetadas, el panel las usa en lugar del dibujo',
      (tester) async {
        _useManifest([
          'assets/sign_language/letras/h.png',
          'assets/sign_language/palabras/hola.gif',
        ]);
        await tester.runAsync(index.ensureLoaded);

        await tester.pumpWidget(panel('hola'));
        await tester.pump();

        String? assetOf(Image image) => image.image is AssetImage
            ? (image.image as AssetImage).assetName
            : null;
        final images = tester
            .widgetList<Image>(find.byType(Image))
            .map(assetOf)
            .toList();
        expect(images, contains('assets/sign_language/letras/h.png'));
        expect(images, contains('assets/sign_language/palabras/hola.gif'));

        // Las fotos no existen de verdad: al fallar, vuelve el dibujo y la
        // mitad de la palabra explica que se está deletreando.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('se deletrea'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('si el manifiesto no se entiende, se sigue dibujando la mano', (
      tester,
    ) async {
      _useManifest(const [], broken: true);

      await tester.runAsync(index.ensureLoaded);

      expect(index.isLoaded, isTrue);
      expect(index.hasAnyLetter, isFalse);
      expect(index.letterAsset('A'), isNull);

      await tester.pumpWidget(panel('a'));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.text('A'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
