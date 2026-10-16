import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/hand_sign_painter_widget.dart';
import 'package:flutter_code4all/ui/core/ui/sign_letter_icon_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';

/// El icono de una letra en dactilología: si el equipo docente deja la foto
/// de esa letra en `assets/sign_language/letras`, se usa la foto; si no, se
/// dibuja la mano en código.
///
/// Hoy no hay ninguna foto empaquetada, así que para probar la regla se le
/// enseña a la app un manifiesto de assets que dice que existe `a.png`. El
/// archivo en sí no existe: así se comprueba también que, si la foto no
/// carga, el icono vuelve al dibujo en vez de quedarse en blanco.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fakeLetter = 'assets/sign_language/letras/a.png';

  /// Lo que hace flutter_test por defecto: servir los assets de la carpeta
  /// de la compilación de pruebas. Se usa para dejarlo todo como estaba.
  ByteData? realAsset(String key) {
    final folder = Platform.environment['UNIT_TEST_ASSETS'];
    if (folder == null) return null;
    final file = File('$folder${Platform.pathSeparator}$key');
    if (!file.existsSync()) return null;
    return Uint8List.fromList(file.readAsBytesSync()).buffer.asByteData();
  }

  Future<ByteData?> Function(ByteData?) assetHandler({required bool fake}) {
    return (ByteData? message) {
      final key = utf8.decode(message!.buffer.asUint8List());
      if (fake && key == 'AssetManifest.bin') {
        final real = realAsset(key);
        final manifest = <Object?, Object?>{
          if (real != null)
            ...(const StandardMessageCodec().decodeMessage(real)
                as Map<Object?, Object?>),
          fakeLetter: <Object?>[],
        };
        return SynchronousFuture(
          const StandardMessageCodec().encodeMessage(manifest),
        );
      }
      return SynchronousFuture(realAsset(key));
    };
  }

  setUp(() {
    SignAssetIndex.instance.debugReset();
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', assetHandler(fake: true));
  });

  tearDown(() {
    SignAssetIndex.instance.debugReset();
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'flutter/assets',
          Platform.environment.containsKey('UNIT_TEST_ASSETS')
              ? assetHandler(fake: false)
              : null,
        );
  });

  Finder handDrawing() => find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is HandPainter,
  );

  Future<void> pumpIcon(WidgetTester tester, String letter) async {
    await tester.pumpWidget(
      Center(child: SignLetterIcon(letter: letter, size: 40)),
    );
    // El manifiesto se lee una vez, de forma asíncrona.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sin foto de la letra se dibuja la mano', (tester) async {
    await pumpIcon(tester, 'B');

    expect(find.byType(Image), findsNothing);
    expect(handDrawing(), findsOneWidget);
    expect(tester.getSize(find.byType(SignLetterIcon)), const Size(40, 40));
  });

  testWidgets('con foto se usa la foto y, si no carga, vuelve el dibujo', (
    tester,
  ) async {
    await pumpIcon(tester, 'a');

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, fakeLetter);

    // La foto no existe de verdad: el icono no se queda vacío.
    await tester.pumpAndSettle();
    expect(handDrawing(), findsOneWidget);
  });

  testWidgets('al cambiar de letra se vuelve a buscar su foto', (tester) async {
    await pumpIcon(tester, 'B');
    expect(find.byType(Image), findsNothing);

    await pumpIcon(tester, 'A');

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('una letra sin seña conocida no dibuja nada', (tester) async {
    await pumpIcon(tester, '#');

    expect(find.byType(Image), findsNothing);
    expect(handDrawing(), findsNothing);
  });
}
