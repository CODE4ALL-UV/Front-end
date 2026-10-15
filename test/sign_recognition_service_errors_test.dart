import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';

/// Respuestas raras del servidor de señas.
///
/// La pantalla de la cámara enseña tal cual el mensaje de cada fallo y decide
/// si seguir haciendo fotos según su tipo, así que importa que cada respuesta
/// acabe en el tipo y el texto correctos. Las pruebas que ya existían cubren
/// los casos principales; aquí van los que faltaban: un estado que no es 200,
/// los motivos vacíos, los códigos inesperados al leer la mano, el formato de
/// la foto y las respuestas con manos a medio describir.
void main() {
  group('saber si se puede usar', () {
    test('un estado distinto de 200 cuenta como no disponible', () async {
      final service = _answering((_) => http.Response('caído', 502));

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, SignFailureKind.unavailable);
      expect(service.lastReason, isNull);
    });

    test('guarda el motivo que da el servidor, pero no uno vacío', () async {
      var reason = '   ';
      final service = _answering(
        (_) => http.Response(
          jsonEncode({'available': false, 'reason': reason}),
          200,
        ),
      );

      expect(await service.isAvailable(), isFalse);
      expect(service.lastReason, isNull);

      reason = 'falta mediapipe';
      expect(await service.isAvailable(refresh: true), isFalse);
      expect(service.lastReason, 'falta mediapipe');
      expect(service.lastFailure, SignFailureKind.unavailable);
    });

    test('al volver a preguntar se olvida el fallo anterior', () async {
      var online = false;
      final service = _answering((_) {
        if (!online) throw http.ClientException('sin red');
        return http.Response(jsonEncode({'available': true}), 200);
      });

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, SignFailureKind.offline);

      online = true;
      expect(await service.isAvailable(refresh: true), isTrue);
      expect(service.lastFailure, isNull);
      expect(service.lastReason, isNull);
    });
  });

  group('mandar una foto', () {
    test('un código inesperado se cuenta con su número', () async {
      final service = _answering((_) => http.Response('error', 500));

      await expectLater(
        service.read(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<SignRecognitionException>()
              .having((error) => error.kind, 'motivo', SignFailureKind.unknown)
              .having(
                (error) => error.toString(),
                'texto',
                'El servidor respondió 500 al leer la mano.',
              ),
        ),
      );
    });

    test('un formato de imagen no admitido es culpa de la foto', () async {
      final service = _answering((_) => http.Response('', 415));

      await expectLater(
        service.read(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<SignRecognitionException>().having(
            (error) => error.kind,
            'motivo',
            SignFailureKind.badImage,
          ),
        ),
      );
    });

    test('la foto viaja con el formato que se indica', () async {
      late String body;
      final service = _answering((request) {
        body = latin1.decode((request as http.Request).bodyBytes);
        return http.Response('{"hands": []}', 200);
      });

      final reading = await service.read(
        Uint8List.fromList([1, 2, 3]),
        format: 'png',
      );

      expect(reading.letter, isNull);
      expect(body, contains('filename="frame.png"'));
      expect(body, contains('content-type: image/png'));
    });
  });

  group('leer la respuesta', () {
    test('una mano sin puntos no se fuerza a ser una letra', () {
      final noPoints = SignRecognitionService.parse(
        jsonEncode({
          'hands': [
            {'handedness': 'Right'},
          ],
        }),
      );
      final notAHand = SignRecognitionService.parse(
        jsonEncode({
          'hands': ['mano'],
        }),
      );

      expect(noPoints.letter, isNull);
      expect(notAHand.letter, isNull);
      expect(noPoints.confidence, 0);
    });
  });
}

SignRecognitionService _answering(
  http.Response Function(http.BaseRequest request) handler,
) {
  return SignRecognitionService(
    api: ApiService(baseUrl: 'http://servidor.de.prueba'),
    client: MockClient((request) async => handler(request)),
  );
}
