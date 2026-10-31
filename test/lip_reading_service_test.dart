import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/lip_reading_service.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_reading_models.dart';

final Uint8List _photo = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);

LipReadingService _serving(
  Future<http.Response> Function(http.Request request) handler,
) => LipReadingService(
  api: ApiService(baseUrl: 'http://servidor.de.prueba'),
  client: MockClient(handler),
);

LipReadingService _answering(Object body, {int status = 200}) => _serving(
  (_) async => http.Response(
    body is String ? body : jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  ),
);

Map<String, dynamic> _point(double x, double y) => {'x': x, 'y': y};

Map<String, dynamic> _faceJson() => {
  'lips': {
    'outer': [_point(0.4, 0.6), _point(0.6, 0.6)],
    'inner': [_point(0.45, 0.6)],
  },
  'opening': 0.26,
  'width': 0.6,
  'rounding': 0.1,
  'shape': 'A',
  'scores': {'A': 0.9},
};

LipFrame _frame({
  double opening = 0,
  double width = 0.6,
  double rounding = 0,
}) => LipFrame(
  outer: const [],
  inner: const [],
  opening: opening,
  width: width,
  rounding: rounding,
  shape: LipShape.closed,
);

void main() {
  group('LipReadingService: disponibilidad', () {
    test('dice que sí y guarda las palabras que sabe leer', () async {
      // Sin declarar la codificación, como contesta FastAPI: las tildes tienen
      // que llegar bien igualmente.
      final service = _serving(
        (_) async => http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'available': true,
              'words': ['hola', 'sí', 7],
            }),
          ),
          200,
        ),
      );

      expect(await service.isAvailable(), isTrue);
      expect(service.words, ['hola', 'sí']);
      expect(service.lastFailure, isNull);
    });

    test('pregunta una vez y recuerda, salvo que se pida otra vez', () async {
      var calls = 0;
      final service = _serving((request) async {
        calls++;
        expect(request.url.path, '/api/lips/status');
        return http.Response(jsonEncode({'available': true}), 200);
      });

      await service.isAvailable();
      await service.isAvailable();
      expect(calls, 1);

      await service.isAvailable(refresh: true);
      expect(calls, 2);
    });

    test('cuando el servidor dice que no, guarda su explicación', () async {
      final service = _answering({
        'available': false,
        'reason': 'Faltan dependencias',
      });

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, LipFailureKind.unavailable);
      expect(service.lastReason, 'Faltan dependencias');
    });

    test('un error del servidor no se confunde con no tener conexión', () async {
      final service = _answering('', status: 500);

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, LipFailureKind.unavailable);
    });

    test('una respuesta sin forma de objeto cuenta como no disponible', () async {
      final service = _answering('[1, 2]');

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, LipFailureKind.unavailable);
    });

    test('sin conexión se dice que no se pudo hablar con él', () async {
      final service = _serving((_) async => throw http.ClientException('red'));

      expect(await service.isAvailable(), isFalse);
      expect(service.lastFailure, LipFailureKind.offline);
    });
  });

  group('LipReadingService: una foto', () {
    test('manda la foto y entiende los labios que devuelve', () async {
      late http.Request sent;
      final service = _serving((request) async {
        sent = request;
        return http.Response(jsonEncode({'face': _faceJson()}), 200);
      });

      final frame = await service.readFrame(_photo);

      expect(sent.url.path, '/api/lips/landmarks');
      final body = latin1.decode(sent.bodyBytes);
      expect(body, contains('name="file"'));
      expect(body, contains('image/jpeg'));
      expect(body, isNot(contains('neutral_width')));

      expect(frame!.shape, LipShape.a);
      expect(frame.opening, 0.26);
      expect(frame.width, 0.6);
      expect(frame.rounding, 0.1);
      expect(frame.outer, hasLength(2));
      expect(frame.outer.first.x, 0.4);
      expect(frame.inner.single.y, 0.6);
    });

    test('manda el ancho de la boca relajada si ya se midió', () async {
      late http.Request sent;
      final service = _serving((request) async {
        sent = request;
        return http.Response(jsonEncode({'face': null}), 200);
      });

      await service.readFrame(_photo, neutralWidth: 0.5512);

      final body = latin1.decode(sent.bodyBytes);
      expect(body, contains('name="neutral_width"'));
      expect(body, contains('0.5512'));
    });

    test('sin cara devuelve null: no es un error', () async {
      final service = _answering({'face': null});

      expect(await service.readFrame(_photo), isNull);
    });

    test('una foto vacía no se llega a mandar', () async {
      var calls = 0;
      final service = _serving((_) async {
        calls++;
        return http.Response('{}', 200);
      });

      await expectLater(
        service.readFrame(Uint8List(0)),
        throwsA(
          isA<LipReadingException>().having(
            (error) => error.kind,
            'kind',
            LipFailureKind.badImage,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('una forma desconocida no rompe la lectura', () {
      final frame = LipReadingService.parseFrame(
        jsonEncode({
          'face': {'shape': 'X'},
        }),
      );

      expect(frame!.shape, LipShape.hidden);
      expect(frame.outer, isEmpty);
      expect(frame.opening, 0);
    });

    final failures = <String, (int, LipFailureKind)>{
      'el servidor no tiene la lectura': (503, LipFailureKind.unavailable),
      'la foto pesa demasiado': (413, LipFailureKind.badImage),
      'el formato no vale': (415, LipFailureKind.badImage),
      'otro error del servidor': (500, LipFailureKind.unknown),
    };
    failures.forEach((name, expected) {
      test('cuando $name se explica', () async {
        final service = _answering('{}', status: expected.$1);

        await expectLater(
          service.readFrame(_photo),
          throwsA(
            isA<LipReadingException>()
                .having((error) => error.kind, 'kind', expected.$2)
                .having((error) => error.toString(), 'text', isNotEmpty),
          ),
        );
      });
    });

    test('sin conexión se dice que no se pudo conectar', () async {
      final service = _serving((_) async => throw http.ClientException('red'));

      await expectLater(
        service.readFrame(_photo),
        throwsA(
          isA<LipReadingException>().having(
            (error) => error.kind,
            'kind',
            LipFailureKind.offline,
          ),
        ),
      );
    });

    for (final body in ['no es json', '[1, 2]']) {
      test('una respuesta que no se entiende se dice: $body', () {
        expect(
          () => LipReadingService.parseFrame(body),
          throwsA(isA<LipReadingException>()),
        );
      });
    }
  });

  group('LipReadingService: un clip', () {
    test('manda todas las fotos en orden y entiende la lectura', () async {
      late http.Request sent;
      final service = _serving((request) async {
        sent = request;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'word': 'adiós',
              'alternatives': ['hola', 3],
              'shapes': ['A', 'I', '?', 'O'],
              'frames': 2,
              'frames_with_face': 2,
              'reason': null,
            }),
          ),
          200,
        );
      });

      final reading = await service.readClip([
        _photo,
        _photo,
      ], neutralWidth: 0.6);

      expect(sent.url.path, '/api/lips/read');
      final body = latin1.decode(sent.bodyBytes);
      expect('name="files"'.allMatches(body), hasLength(2));
      expect(body, contains('name="neutral_width"'));

      expect(reading.word, 'adiós');
      expect(reading.alternatives, ['hola']);
      expect(reading.shapes, [LipShape.a, LipShape.i, LipShape.o]);
      expect(reading.problem, isNull);
    });

    test('sin fotos es demasiado corto, sin molestar al servidor', () async {
      var calls = 0;
      final service = _serving((_) async {
        calls++;
        return http.Response('{}', 200);
      });

      final reading = await service.readClip(const []);

      expect(reading.problem, LipReadingProblem.tooShort);
      expect(calls, 0);
    });

    final reasons = <String, LipReadingProblem>{
      'too_short': LipReadingProblem.tooShort,
      'no_face': LipReadingProblem.noFace,
      'no_movement': LipReadingProblem.noMovement,
    };
    reasons.forEach((reason, problem) {
      test('entiende por qué no se pudo leer: $reason', () {
        final reading = LipReadingService.parseClip(
          jsonEncode({'word': null, 'reason': reason}),
        );

        expect(reading.problem, problem);
        expect(reading.word, isNull);
        expect(reading.alternatives, isEmpty);
      });
    });

    test('dudar no es un problema: llegan las candidatas', () {
      final reading = LipReadingService.parseClip(
        jsonEncode({
          'word': null,
          'alternatives': ['hola', 'no'],
          'reason': null,
        }),
      );

      expect(reading.word, isNull);
      expect(reading.problem, isNull);
      expect(reading.alternatives, ['hola', 'no']);
    });
  });

  group('LipCalibration', () {
    test('mide la boca relajada con la mediana de varias fotos', () {
      final calibration = LipCalibration(framesNeeded: 3);

      calibration.offer(_frame(width: 0.5));
      expect(calibration.isDone, isFalse);
      expect(calibration.neutralWidth, isNull);
      expect(calibration.progress, closeTo(1 / 3, 0.01));

      calibration.offer(_frame(width: 0.9)); // Un gesto suelto.
      calibration.offer(_frame(width: 0.55));

      expect(calibration.isDone, isTrue);
      expect(calibration.neutralWidth, 0.55);
      expect(calibration.progress, 1);
    });

    test('no cuenta las fotos con la boca abierta o redonda', () {
      final calibration = LipCalibration(framesNeeded: 1);

      calibration.offer(_frame(opening: 0.2));
      calibration.offer(_frame(rounding: 0.8));
      expect(calibration.neutralWidth, isNull);

      calibration.offer(_frame(width: 0.58));
      expect(calibration.neutralWidth, 0.58);
    });

    test('quien no consigue relajar la boca también puede seguir', () {
      final calibration = LipCalibration(framesNeeded: 2, giveUpAfter: 3);

      for (var i = 0; i < 3; i++) {
        calibration.offer(_frame(opening: 0.3));
      }

      expect(calibration.isDone, isTrue);
      expect(calibration.neutralWidth, isNull);
    });

    test('ya medida no cambia, y se puede volver a empezar', () {
      final calibration = LipCalibration(framesNeeded: 1);

      calibration.offer(_frame(width: 0.5));
      calibration.offer(_frame(width: 0.9));
      expect(calibration.neutralWidth, 0.5);

      calibration.reset();
      expect(calibration.isDone, isFalse);
      expect(calibration.neutralWidth, isNull);
      expect(calibration.progress, 0);
    });
  });

  test('cada forma de boca se encuentra por su código', () {
    for (final shape in LipShape.values) {
      expect(LipShape.fromCode(shape.code), shape);
      expect(shape.description, isNotEmpty);
    }
    expect(LipShape.fromCode('X'), isNull);
    expect(LipShape.fromCode(null), isNull);
  });
}
