import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';

/// Una sesión de mentira: con [token] nulo es que nadie ha entrado.
class _Session extends AuthStorage {
  _Session([this.token = 'token-de-direccion']);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// El almacén del seguimiento cuando el servidor no contesta lo esperado.
///
/// La pantalla de la dirección enseña el mensaje que deja el almacén, así
/// que cada fallo tiene que acabar en un texto que explique qué pasó y no en
/// una excepción suelta. Y al guardar bien, lo que se ve se tiene que poner
/// al día sin que nadie lo pida.
void main() {
  final store = DirectorOversightStore.instance;
  final api = ApiService(baseUrl: 'http://servidor.de.prueba');

  late List<http.Request> requests;

  void serve(
    Future<http.Response> Function(http.Request) handler, {
    AuthStorage? auth,
  }) {
    store.debugUse(
      api: api,
      client: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
      auth: auth ?? _Session(),
    );
  }

  setUp(() {
    requests = [];
    store.debugReset();
  });

  tearDown(store.debugReset);

  group('al cargar el seguimiento', () {
    test('una respuesta que no es 200 dice qué código llegó', () async {
      serve((_) async => _json({'detail': 'roto'}, 502));

      await store.refresh();

      expect(store.problem, 'El servidor no devolvió los datos (502).');
      expect(store.isLoaded, isTrue);
      expect(store.isLoading, isFalse);
    });

    test('sin conexión no revienta: lo dice', () async {
      serve((_) async => throw http.ClientException('sin red'));

      await store.refresh();

      expect(store.problem, 'No se pudo consultar el servidor.');
      expect(store.teachers, isEmpty);
    });

    test('con el servidor de antes no hay cursos, pero sí lo demás', () async {
      serve((request) async {
        switch (request.url.path) {
          case '/api/oversight/teachers':
            return _json({
              'teachers': [
                {'user_id': 3, 'nombre': 'Laura', 'avg_score': 4},
                'basura',
              ],
            }, 200);
          case '/api/oversight/content':
            return _json({'items': 'no es una lista'}, 200);
        }
        return _json({'detail': 'Not Found'}, 404);
      });

      await store.refresh();

      expect(store.problem, isNull);
      expect(store.teachers.single.name, 'Laura');
      expect(store.teachers.single.avgScore, 4.0);
      expect(store.verdicts, isEmpty);
      expect(store.coursesSupported, isFalse);
      expect(store.courses, isEmpty);
    });

    test('mientras carga, pedirlo otra vez no repite las peticiones', () async {
      final gate = Completer<void>();
      serve((_) async {
        await gate.future;
        return _json({'teachers': [], 'items': [], 'courses': []}, 200);
      });

      final first = store.refresh();
      final second = store.refresh();
      expect(store.isLoading, isTrue);
      gate.complete();
      await Future.wait([first, second]);

      expect(requests, hasLength(3), reason: 'docentes, contenido y cursos');
    });
  });

  group('al pedir el detalle de un docente', () {
    test('si falla la actividad dice el código', () async {
      serve((_) async => _json({'detail': 'no'}, 500));

      await expectLater(
        store.activityOf(7),
        throwsA(
          isA<OversightException>().having(
            (e) => e.toString(),
            'mensaje',
            'No se pudo consultar su actividad (500).',
          ),
        ),
      );
    });

    test('si fallan las valoraciones dice el código', () async {
      serve((_) async => _json({'detail': 'no'}, 403));

      await expectLater(
        store.reviewsOf(7),
        throwsA(
          isA<OversightException>().having(
            (e) => e.message,
            'mensaje',
            'No se pudieron consultar sus valoraciones (403).',
          ),
        ),
      );
      expect(requests.single.url.path, '/api/oversight/reviews/7');
      expect(
        requests.single.headers['Authorization'],
        'Bearer token-de-direccion',
      );
    });
  });

  group('al guardar', () {
    Future<http.Response> acceptAll(http.Request request) async {
      if (request.method != 'GET') return _json({'ok': true}, 201);
      return switch (request.url.path) {
        '/api/oversight/teachers' => _json({
          'teachers': [
            {'user_id': 7, 'nombre': 'Mateo', 'reviews': 1, 'last_score': 5},
          ],
        }, 200),
        '/api/oversight/content' => _json({
          'items': [
            {'course_id': 5, 'section_id': 'm1-s1', 'status': 'observado'},
          ],
        }, 200),
        _ => _json({'detail': 'Not Found'}, 404),
      };
    }

    test('una valoración guardada pone al día el resumen', () async {
      serve(acceptAll);

      await store.review(userId: 7, score: 5, comment: 'Excelente trabajo.');

      final post = requests.first;
      expect(post.method, 'POST');
      expect(post.headers['Content-Type'], 'application/json');
      expect(jsonDecode(post.body), {
        'docente_id': 7,
        'score': 5,
        'comment': 'Excelente trabajo.',
      });
      // Después vuelve a pedir el seguimiento y ya trae la nota nueva.
      expect(store.teachers.single.lastScore, 5);
    });

    test('una revisión va con el curso y pone al día el contenido', () async {
      serve(acceptAll);

      await store.judgeContent(
        sectionId: 'm1-s1',
        approved: false,
        comment: 'Revisar el ejemplo.',
        courseId: 5,
      );

      final put = requests.first;
      expect(put.method, 'PUT');
      expect(put.url.path, '/api/oversight/content/m1-s1');
      expect(jsonDecode(put.body), {
        'section_id': 'm1-s1',
        'status': 'observado',
        'comment': 'Revisar el ejemplo.',
        'course_id': 5,
      });
      expect(store.verdictOf('m1-s1', courseId: 5)?.status, 'observado');
    });

    test('sin curso, la revisión no manda course_id', () async {
      serve(acceptAll);

      await store.judgeContent(sectionId: 'm1-s1', approved: true, comment: '');

      final body = jsonDecode(requests.first.body) as Map;
      expect(body['status'], 'aprobado');
      expect(body.containsKey('course_id'), isFalse);
    });

    test('sin sesión no se manda nada y se pide volver a entrar', () async {
      serve(acceptAll, auth: _Session(null));

      for (final save in [
        () => store.review(userId: 7, score: 4, comment: 'Bien.'),
        () =>
            store.judgeContent(sectionId: 'm1-s1', approved: true, comment: ''),
      ]) {
        await expectLater(
          save(),
          throwsA(
            isA<OversightException>().having(
              (e) => e.message,
              'mensaje',
              'Tu sesión no está iniciada. Vuelve a entrar.',
            ),
          ),
        );
      }
      expect(requests, isEmpty);
    });

    test('sin conexión dice que el servidor no responde', () async {
      serve((_) async => throw http.ClientException('sin red'));

      for (final save in [
        () => store.review(userId: 7, score: 4, comment: 'Bien.'),
        () =>
            store.judgeContent(sectionId: 'm1-s1', approved: true, comment: ''),
      ]) {
        await expectLater(
          save(),
          throwsA(
            isA<OversightException>().having(
              (e) => e.message,
              'mensaje',
              'El servidor no responde.',
            ),
          ),
        );
      }
    });

    test('un error sin detalle legible dice que no se pudo guardar', () async {
      serve((_) async => http.Response('<html>500</html>', 500));

      await expectLater(
        store.review(userId: 7, score: 4, comment: 'Bien.'),
        throwsA(
          isA<OversightException>().having(
            (e) => e.message,
            'mensaje',
            'No se pudo guardar.',
          ),
        ),
      );
    });
  });

  test('la revisión dice el título de la sección, no su identificador', () {
    final verdict = ContentVerdict.fromJson({
      'section_id': 'm1-s1',
      'status': 'aprobado',
      'reviewed_at': '2026-10-01T10:00:00Z',
    });
    expect(
      verdict.sectionTitle,
      PythonCourseCatalog.sectionById('m1-s1')!.title,
    );
    expect(verdict.reviewedAt, DateTime.utc(2026, 10, 1, 10));
    expect(verdict.comment, '');

    // Si la sección ya no existe se usa el identificador.
    const gone = ContentVerdict(
      sectionId: 'seccion-borrada',
      status: 'observado',
      comment: '',
      outdated: false,
    );
    expect(gone.sectionTitle, 'seccion-borrada');
  });
}
