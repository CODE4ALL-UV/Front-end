import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('leer la respuesta del servidor', () {
    test('sin manos a la vista no es un error, es que no hay mano', () {
      final reading = SignRecognitionService.parse('{"hands": []}');

      expect(reading.letter, isNull);
      expect(reading.confidence, 0);
    });

    test('una mano con sus 21 puntos se convierte en una letra', () {
      // Un puño con el pulgar al lado: la A.
      final reading = SignRecognitionService.parse(
        jsonEncode({
          'hands': [
            {'handedness': 'Right', 'landmarks': _fistWithThumbOut},
          ],
        }),
      );

      expect(reading.letter, 'A');
      expect(reading.isConfident, isTrue);
    });

    test('una mano a medio llegar no se fuerza a ser una letra', () {
      final reading = SignRecognitionService.parse(
        jsonEncode({
          'hands': [
            {
              'landmarks': [
                {'x': 0.5, 'y': 0.5, 'z': 0.0},
              ],
            },
          ],
        }),
      );

      expect(reading.letter, isNull);
    });

    test('una respuesta que no se entiende se avisa como tal', () {
      expect(
        () => SignRecognitionService.parse('esto no es json'),
        throwsA(isA<SignRecognitionException>()),
      );
      expect(
        () => SignRecognitionService.parse('{"otra":"cosa"}'),
        throwsA(isA<SignRecognitionException>()),
      );
    });
  });

  group('saber si se puede usar', () {
    test('el servidor dice que sí', () async {
      final service = _serviceThatAnswers(
        (request) => http.Response(
          jsonEncode({'available': true, 'model_ready': true}),
          200,
        ),
      );

      expect(await service.isAvailable(), isTrue);
    });

    test('el servidor dice que le faltan dependencias', () async {
      final service = _serviceThatAnswers(
        (request) => http.Response(
          jsonEncode({'available': false, 'reason': 'falta mediapipe'}),
          200,
        ),
      );

      expect(await service.isAvailable(), isFalse);
    });

    test('el servidor apagado no revienta: simplemente no está', () async {
      final service = _serviceThatAnswers((request) {
        throw const SocketExceptionLike();
      });

      expect(await service.isAvailable(), isFalse);
    });

    test('la respuesta se recuerda para no preguntar en cada foto', () async {
      var calls = 0;
      final service = _serviceThatAnswers((request) {
        calls++;
        return http.Response(jsonEncode({'available': true}), 200);
      });

      await service.isAvailable();
      await service.isAvailable();

      expect(calls, 1);
      expect(await service.isAvailable(refresh: true), isTrue);
      expect(calls, 2);
    });
  });

  group('mandar una foto', () {
    test('una foto vacía no se llega a mandar', () async {
      final service = _serviceThatAnswers(
        (request) => throw StateError('no debería haberse llamado'),
      );

      await expectLater(
        service.read(Uint8List(0)),
        throwsA(
          isA<SignRecognitionException>().having(
            (error) => error.kind,
            'motivo',
            SignFailureKind.badImage,
          ),
        ),
      );
    });

    test('la foto se manda como imagen, no como bytes sueltos', () async {
      String? contentType;
      final service = _serviceThatAnswers((request) {
        contentType = request.headers['content-type'];
        return http.Response('{"hands": []}', 200);
      });

      await service.read(Uint8List.fromList([1, 2, 3]));

      // El backend rechaza cualquier cosa que no sea una imagen declarada.
      expect(contentType, contains('multipart/form-data'));
    });

    test('si al servidor le falta el reconocimiento se dice con claridad', () async {
      final service = _serviceThatAnswers(
        (request) => http.Response('{"detail":"falta mediapipe"}', 503),
      );

      await expectLater(
        service.read(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<SignRecognitionException>().having(
            (error) => error.kind,
            'motivo',
            SignFailureKind.unavailable,
          ),
        ),
      );
    });

    test('una foto rechazada se distingue de un servidor caído', () async {
      final service = _serviceThatAnswers(
        (request) => http.Response('{"detail":"muy grande"}', 413),
      );

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

    test('sin conexión se avisa de que no se pudo llegar al servidor', () async {
      final service = _serviceThatAnswers((request) {
        throw const SocketExceptionLike();
      });

      await expectLater(
        service.read(Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<SignRecognitionException>().having(
            (error) => error.kind,
            'motivo',
            SignFailureKind.offline,
          ),
        ),
      );
    });
  });
}

SignRecognitionService _serviceThatAnswers(MockClientHandler handler) {
  return SignRecognitionService(
    api: ApiService(baseUrl: 'http://servidor.de.prueba'),
    client: MockClient((request) async => handler(request)),
  );
}

/// Un fallo de red cualquiera, sin depender de `dart:io` para que la prueba
/// también corra en web.
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}

/// Los 21 puntos de un puño con el pulgar separado: la letra A.
///
/// La muñeca abajo, los nudillos encima y cada dedo doblado sobre la palma.
const List<Map<String, double>> _fistWithThumbOut = [
  {'x': 0.50, 'y': 0.90, 'z': 0.0}, // muñeca
  {'x': 0.44, 'y': 0.84, 'z': 0.0}, // pulgar: base
  {'x': 0.41, 'y': 0.75, 'z': 0.0},
  {'x': 0.38, 'y': 0.66, 'z': 0.0},
  {'x': 0.36, 'y': 0.58, 'z': 0.0}, // pulgar: punta, separado
  {'x': 0.42, 'y': 0.68, 'z': 0.0}, // índice, recogido
  {'x': 0.42, 'y': 0.59, 'z': 0.0},
  {'x': 0.48, 'y': 0.60, 'z': 0.0},
  {'x': 0.47, 'y': 0.64, 'z': 0.0},
  {'x': 0.49, 'y': 0.68, 'z': 0.0}, // corazón, recogido
  {'x': 0.49, 'y': 0.58, 'z': 0.0},
  {'x': 0.55, 'y': 0.59, 'z': 0.0},
  {'x': 0.54, 'y': 0.64, 'z': 0.0},
  {'x': 0.56, 'y': 0.68, 'z': 0.0}, // anular, recogido
  {'x': 0.56, 'y': 0.59, 'z': 0.0},
  {'x': 0.62, 'y': 0.60, 'z': 0.0},
  {'x': 0.61, 'y': 0.64, 'z': 0.0},
  {'x': 0.63, 'y': 0.68, 'z': 0.0}, // meñique, recogido
  {'x': 0.63, 'y': 0.61, 'z': 0.0},
  {'x': 0.68, 'y': 0.62, 'z': 0.0},
  {'x': 0.67, 'y': 0.66, 'z': 0.0},
];

typedef MockClientHandler = http.Response Function(http.BaseRequest request);
