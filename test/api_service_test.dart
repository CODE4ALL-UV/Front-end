import 'dart:convert';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// IMPORTANTE: Ajusta estas rutas a tu proyecto real
// import 'package:tu_app/data/services/api_service.dart';
// import 'package:tu_app/data/models/auth_models.dart';

void main() {
  group('ApiService Tests', () {
    const String testUrl = 'https://miapp.com';

    test('buildUrl y resolveMediaUrl formatean correctamente las rutas', () {
      final api = ApiService(baseUrl: testUrl);

      // Prueba buildUrl
      expect(api.buildUrl('api/login'), '$testUrl/api/login');
      expect(api.buildUrl('/api/login'), '$testUrl/api/login');

      // Prueba resolveMediaUrl
      expect(api.resolveMediaUrl(''), '');
      expect(api.resolveMediaUrl(null), '');
      expect(
        api.resolveMediaUrl('https://otro.com/img.png'),
        'https://otro.com/img.png',
      );
      expect(api.resolveMediaUrl('/media/foto.png'), '$testUrl/media/foto.png');
      expect(api.resolveMediaUrl('media/foto.png'), '$testUrl/media/foto.png');
    });

    test('register retorna RegisterResponse cuando el status es 201', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id_usuario': 1,
            'nombre': 'Juan',
            'correo': 'juan@test.com',
            'rol': 'estudiante',
            'fecha_registro': '2023-10-01T10:00:00Z',
          }),
          201,
        );
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final response = await api.register(
        nombre: 'Juan',
        correo: 'juan@test.com',
        password: '123',
        rol: 'estudiante',
      );

      expect(response.nombre, 'Juan');
      expect(response.idUsuario, 1);
    });

    test('register lanza ApiException cuando el status no es 201', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'El correo ya existe'}),
          400,
        );
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);

      expect(
        () => api.register(
          nombre: 'J',
          correo: 'j@test.com',
          password: '1',
          rol: 'estudiante',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'El correo ya existe',
          ),
        ),
      );
    });

    test('login retorna LoginResponse cuando el status es 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'token123',
            'token_type': 'Bearer',
            'user_id': 1,
            'email': 'juan@test.com',
            'nombre': 'Juan',
            'rol': 'estudiante',
          }),
          200,
        );
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final response = await api.login(email: 'juan@test.com', password: '123');

      expect(response.accessToken, 'token123');
      expect(response.nombre, 'Juan');
    });

    test('getStudents retorna lista dinámica en 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'nombre': 'Alumno 1'},
            {'nombre': 'Alumno 2'},
          ]),
          200,
        );
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final list = await api.getStudents(bearerToken: 'token');

      expect(list.length, 2);
      expect(list[0]['nombre'], 'Alumno 1');
    });

    test('Peticiones simulan error de red (Exception)', () async {
      // Forzamos un error de conexión
      final mockClient = MockClient((request) async {
        throw Exception('Sin internet');
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);

      expect(
        () => api.login(email: 'a@a.com', password: '123'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('No se pudo conectar con el servidor'),
          ),
        ),
      );
    });

    test(
      'signInWithFacebook procesa _postJson correctamente y maneja 404',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final api = ApiService(baseUrl: testUrl, client: mockClient);

        // Como tu método tiene un notFound personalizado, validamos que se extraiga
        expect(
          () => api.signInWithFacebook(code: '123', redirectUri: 'uri'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'El inicio con Facebook todavía no está disponible en el servidor.',
            ),
          ),
        );
      },
    );

    test('requestPasswordReset retorna detail exitosamente', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Correo enviado'}), 200);
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final result = await api.requestPasswordReset('test@test.com');

      expect(result, 'Correo enviado');
    });

    test('Manejo de JSON corrupto en _extractMessage', () async {
      final mockClient = MockClient((request) async {
        // Devolvemos un string que no es JSON para forzar el catch interno
        return http.Response('Error de servidor interno sin JSON', 500);
      });

      final api = ApiService(baseUrl: testUrl, client: mockClient);

      expect(
        () => api.login(email: 'a@a.com', password: '123'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Ocurrió un error inesperado',
          ),
        ),
      );
    });

    test('getPerformances retorna datos en 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'data': 'ok'},
          ]),
          200,
        );
      });
      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final list = await api.getPerformances(bearerToken: 'token');
      expect(list.isNotEmpty, true);
    });

    test('getPerformancesAggregate retorna datos en 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'data': 'ok'},
          ]),
          200,
        );
      });
      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final list = await api.getPerformancesAggregate(bearerToken: 'token');
      expect(list.isNotEmpty, true);
    });

    test('getPerformancesAverage retorna datos en 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'data': 'ok'},
          ]),
          200,
        );
      });
      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final list = await api.getPerformancesAverage(bearerToken: 'token');
      expect(list.isNotEmpty, true);
    });

    test('signInWithGoogle retorna LoginResponse al recibir 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'token123',
            'token_type': 'Bearer',
            'user_id': 1,
            'email': 'g@test.com',
            'nombre': 'Google User',
            'rol': 'estudiante',
          }),
          200,
        );
      });
      final api = ApiService(baseUrl: testUrl, client: mockClient);
      final response = await api.signInWithGoogle(
        accessToken: 'a',
        idToken: 'i',
      );
      expect(response.email, 'g@test.com');
    });

    test(
      'Lanza ApiException genérica (captura catch y notFound ternario) en error de cliente no controlado',
      () async {
        final mockClient = MockClient((request) async {
          throw const FormatException('Error de formato crudo');
        });
        final api = ApiService(baseUrl: testUrl, client: mockClient);

        expect(
          () => api.signInWithGoogle(accessToken: 'a', idToken: 'i'),
          throwsA(
            isA<ApiException>(),
          ), // Esto cubre la línea throw ApiException(statusCode: null, message: _connectionErrorMessage())
        );
      },
    );
  });
}
