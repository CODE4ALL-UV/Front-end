import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Ajusta las rutas según la estructura real de tu proyecto
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';

// import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';

class FakeAuthStorage extends AuthStorage {
  String? dummyToken = 'valid_token';

  @override
  Future<String?> getToken() async => dummyToken;
}

class FakeApiService extends ApiService {
  @override
  String buildUrl(String endpoint) => 'https://backend.test$endpoint';
}

void main() {
  group('MyCoursesStore', () {
    late MyCoursesStore store;
    late FakeAuthStorage fakeAuth;
    late FakeApiService fakeApi;

    setUp(() {
      store = MyCoursesStore.instance;
      store.debugReset();
      fakeAuth = FakeAuthStorage();
      fakeApi = FakeApiService();
    });

    test('clear() reinicia todos los valores al estado por defecto', () {
      // Forzamos un estado "sucio" (se asume que _courses y _problem se modifican vía reflection o tras un refresh fallido/exitoso)
      store.clear();

      expect(store.courses, isEmpty);
      expect(store.active, isNull);
      expect(store.generalCourseId, isNull);
      expect(store.supported, isNull);
      expect(store.problem, isNull);
      expect(store.isLoading, false);
    });

    group('refresh()', () {
      test(
        'Maneja 404 configurando supported en false (modo legacy)',
        () async {
          final mockClient = MockClient((req) async => http.Response('', 404));
          store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

          await store.refresh();

          expect(store.supported, false);
          expect(store.courses, isEmpty);
          expect(store.problem, isNull);
        },
      );

      test('Maneja 401 indicando problema de sesión', () async {
        final mockClient = MockClient((req) async => http.Response('', 401));
        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

        await store.refresh();

        expect(store.problem, 'Tu sesión caducó. Vuelve a iniciar sesión.');
      });

      test('Maneja 200 OK decodificando los cursos correctamente', () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer valid_token');
          final jsonResponse = {
            "general_course_id": 99,
            "courses": [
              {"id": 1, "title": "Curso A", "is_general": false},
              {"id": 99, "title": "Curso General", "is_general": true},
            ],
          };
          return http.Response(jsonEncode(jsonResponse), 200);
        });

        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

        await store.refresh();

        expect(store.supported, true);
        expect(store.generalCourseId, 99);
        expect(store.courses.length, 2);
        expect(store.problem, isNull);
      });

      test('Maneja excepciones de red correctamente', () async {
        final mockClient = MockClient((req) async {
          throw Exception('Network Error');
        });
        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

        await store.refresh();

        expect(
          store.problem,
          'No se pudo consultar tus cursos. Revisa tu conexión.',
        );
      });
    });

    group('Acciones de red (_send)', () {
      test('create() envía el body correcto y actualiza el estado', () async {
        bool refreshCalled = false;

        final mockClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.contains('/api/courses') &&
              !request.url.path.contains('mine')) {
            final body = jsonDecode(request.body);
            expect(body['title'], 'Nuevo Curso');
            expect(body['description'], 'Desc');
            return http.Response('{"id": 10, "title": "Nuevo Curso"}', 201);
          }
          if (request.url.path.contains('/api/courses/mine')) {
            refreshCalled = true;
            return http.Response(
              '{"courses": [{"id": 10, "title": "Nuevo Curso"}]}',
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

        final course = await store.create(
          title: 'Nuevo Curso',
          description: 'Desc',
        );

        expect(course.id, 10);
        expect(refreshCalled, true); // Verifica que encadenó el refresh()
      });

      test('join() envía el código correcto', () async {
        final mockClient = MockClient((request) async {
          if (request.method == 'POST' && request.url.path.contains('/join')) {
            final body = jsonDecode(request.body);
            expect(body['code'], 'XYZ123');
            return http.Response('{"id": 5, "title": "Curso Unido"}', 200);
          }
          return http.Response(
            '{"courses": []}',
            200,
          ); // Mock para el refresh posterior
        });

        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);
        await store.join('XYZ123');
      });

      test(
        'Lanza CourseActionException con el detalle del servidor en errores 400+',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response('{"detail": "Código inválido"}', 400);
          });

          store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

          expect(
            () => store.join('INVALID'),
            throwsA(
              isA<CourseActionException>().having(
                (e) => e.message,
                'message',
                'Código inválido',
              ),
            ),
          );
        },
      );

      test(
        'Lanza CourseActionException genérico si el servidor falla sin mensaje',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response('Internal Server Error', 500);
          });

          store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

          expect(
            () => store.join('ANY'),
            throwsA(
              isA<CourseActionException>().having(
                (e) => e.message,
                'message',
                'No se pudo completar (error 500).',
              ),
            ),
          );
        },
      );
    });
  });
}
