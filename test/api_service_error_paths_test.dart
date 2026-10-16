import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Matcher _apiError(int? status, Object message) => isA<ApiException>()
    .having((e) => e.statusCode, 'statusCode', status)
    .having((e) => e.message, 'message', message);

/// Lo que llega a la pantalla cuando el servidor dice que no.
///
/// Cada error del servidor tiene que convertirse en un [ApiException] con un
/// mensaje que se pueda enseñar tal cual: el `detail` del servidor si lo
/// trae, una explicación de conexión si no hubo respuesta, y nunca un
/// «Not Found» o un volcado de HTML.
void main() {
  const base = 'http://servidor.de.prueba';

  late List<http.Request> requests;

  ApiService api(Future<http.Response> Function(http.Request) handler) =>
      ApiService(
        baseUrl: '  $base  ',
        client: MockClient((request) {
          requests.add(request);
          return handler(request);
        }),
      );

  setUp(() => requests = []);

  test('la dirección del servidor se guarda sin espacios', () {
    expect(api((_) async => _json({}, 200)).baseUrl, base);
  });

  group('consultas de la dirección', () {
    final calls = <String, Future<List<dynamic>> Function(ApiService)>{
      '/api/director/students': (a) => a.getStudents(bearerToken: 't'),
      '/api/director/performances': (a) => a.getPerformances(bearerToken: 't'),
      '/api/director/performances/aggregate': (a) =>
          a.getPerformancesAggregate(bearerToken: 't'),
      '/api/director/performances/average': (a) =>
          a.getPerformancesAverage(bearerToken: 't'),
    };

    for (final MapEntry(key: path, value: call) in calls.entries) {
      test('$path devuelve la lista con el token de la sesión', () async {
        final service = api(
          (_) async => _json([
            {'id': 1},
          ], 200),
        );

        expect(await call(service), [
          {'id': 1},
        ]);
        expect(requests.single.url.toString(), '$base$path');
        expect(requests.single.headers['Authorization'], 'Bearer t');
      });

      test('$path sin permiso trae el motivo del servidor', () async {
        final service = api(
          (_) async => _json({'detail': 'Solo para la dirección.'}, 403),
        );

        await expectLater(
          call(service),
          throwsA(_apiError(403, 'Solo para la dirección.')),
        );
      });
    }

    test('un error sin JSON dice que fue inesperado', () async {
      final service = api((_) async => http.Response('<h1>Error</h1>', 500));

      await expectLater(
        service.getStudents(bearerToken: 't'),
        throwsA(_apiError(500, 'Ocurrió un error inesperado')),
      );
    });

    test('un JSON sin detail también', () async {
      final service = api((_) async => _json({'error': 'x'}, 500));

      await expectLater(
        service.getPerformances(bearerToken: 't'),
        throwsA(_apiError(500, 'Ocurrió un error inesperado')),
      );
    });
  });

  group('registro e inicio con Google', () {
    test('registro sin conexión explica que no hay servidor', () async {
      final service = api((_) async => throw http.ClientException('sin red'));

      await expectLater(
        service.register(
          nombre: 'Ana',
          correo: 'ana@example.com',
          password: 'clave-de-prueba',
          rol: 'estudiante',
        ),
        throwsA(
          _apiError(null, contains('No se pudo conectar con el servidor')),
        ),
      );
    });

    test('Google manda solo los tokens que hay', () async {
      final service = api(
        (_) async => _json({
          'access_token': 'sesion',
          'token_type': 'bearer',
          'user_id': 1,
          'email': 'ana@example.com',
          'nombre': 'Ana',
          'rol': 'estudiante',
        }, 200),
      );

      final session = await service.signInWithGoogle(idToken: 'identidad');

      expect(session.accessToken, 'sesion');
      expect(jsonDecode(requests.single.body), {'id_token': 'identidad'});
    });

    test('Google sin configurar en el servidor (503) trae el motivo', () async {
      final service = api(
        (_) async => _json({
          'detail': 'El inicio con Google no está configurado en el servidor.',
        }, 503),
      );

      await expectLater(
        service.signInWithGoogle(accessToken: 'acceso'),
        throwsA(
          _apiError(
            503,
            'El inicio con Google no está configurado en el servidor.',
          ),
        ),
      );
    });

    test('Google sin conexión explica que no hay servidor', () async {
      final service = api((_) async => throw http.ClientException('sin red'));

      await expectLater(
        service.signInWithGoogle(accessToken: 'acceso'),
        throwsA(
          _apiError(null, contains('No se pudo conectar con el servidor')),
        ),
      );
    });
  });

  group('recuperar la contraseña', () {
    test('pedir el enlace manda el correo y devuelve lo que dice', () async {
      final service = api(
        (_) async =>
            _json({'detail': 'Si hay una cuenta, te escribimos.'}, 200),
      );

      expect(
        await service.requestPasswordReset('ana@example.com'),
        'Si hay una cuenta, te escribimos.',
      );
      expect(requests.single.url.path, '/api/auth/password/forgot');
      expect(jsonDecode(requests.single.body), {'correo': 'ana@example.com'});
    });

    test('guardar la contraseña nueva manda el token del enlace', () async {
      final service = api((_) async => _json({'detail': 'Listo.'}, 200));

      expect(
        await service.resetPassword(
          token: 'token-del-correo',
          password: 'nueva-clave',
        ),
        'Listo.',
      );
      expect(requests.single.url.path, '/api/auth/password/reset');
      expect(jsonDecode(requests.single.body), {
        'token': 'token-del-correo',
        'password': 'nueva-clave',
      });
    });

    test('una respuesta buena sin cuerpo se toma como vacía', () async {
      final service = api((_) async => http.Response('', 204));

      expect(await service.requestPasswordReset('ana@example.com'), '');
    });

    test('una respuesta buena que no es un objeto también', () async {
      final service = api((_) async => _json(['inesperado'], 200));

      expect(
        await service.resetPassword(token: 't', password: 'nueva-clave'),
        '',
      );
    });

    test('un enlace caducado trae el motivo del servidor', () async {
      final service = api(
        (_) async => _json({
          'detail':
              'El enlace ya no sirve: caducó o ya se usó. Pide uno nuevo.',
        }, 400),
      );

      await expectLater(
        service.resetPassword(token: 'viejo', password: 'nueva-clave'),
        throwsA(_apiError(400, contains('caducó'))),
      );
    });

    test(
      'con el servidor de antes (404) dice que aún no está disponible',
      () async {
        final service = api((_) async => _json({'detail': 'Not Found'}, 404));

        await expectLater(
          service.requestPasswordReset('ana@example.com'),
          throwsA(
            _apiError(
              404,
              'La recuperación de contraseña todavía no está disponible en el '
              'servidor.',
            ),
          ),
        );
      },
    );

    test('sin conexión explica que no hay servidor', () async {
      final service = api((_) async => throw http.ClientException('sin red'));

      await expectLater(
        service.resetPassword(token: 't', password: 'nueva-clave'),
        throwsA(
          _apiError(null, contains('No se pudo conectar con el servidor')),
        ),
      );
    });
  });
}
