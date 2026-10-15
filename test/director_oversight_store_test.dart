import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Ajusta estas rutas a las reales de tu proyecto
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';

// import 'package:flutter_code4all/director_oversight_store.dart'; // Importa tu archivo

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
  group('Modelos de Seguimiento (Oversight)', () {
    test('TeacherSummary detecta si no ha editado o no tiene revisiones', () {
      const activeReviewed = TeacherSummary(
        userId: 1,
        name: 'A',
        email: '',
        edits: 5,
        reviews: 2,
      );
      const lazyNew = TeacherSummary(
        userId: 2,
        name: 'B',
        email: '',
        edits: 0,
        reviews: 0,
      );

      expect(activeReviewed.hasNotEdited, false);
      expect(activeReviewed.neverReviewed, false);

      expect(lazyNew.hasNotEdited, true);
      expect(lazyNew.neverReviewed, true);
    });

    test('TeacherEdit formatea correctamente el título según el scope', () {
      const moduleEdit = TeacherEdit(
        scope: 'module',
        targetId: '1',
        reviewOutdated: false,
      );
      const sectionEdit = TeacherEdit(
        scope: 'section',
        targetId: 'unknown_sec',
        reviewOutdated: false,
      );

      expect(moduleEdit.title, 'Módulo 1 (nombre)');
      expect(
        sectionEdit.title,
        'unknown_sec',
      ); // Falla silenciosamente al ID si no está en el catálogo
    });

    test('ContentVerdict identifica aprobados', () {
      const approved = ContentVerdict(
        sectionId: '1',
        status: 'aprobado',
        comment: '',
        outdated: false,
      );
      const flagged = ContentVerdict(
        sectionId: '2',
        status: 'observado',
        comment: '',
        outdated: true,
      );

      expect(approved.isApproved, true);
      expect(flagged.isApproved, false);
    });
  });

  group('DirectorOversightStore - Lógica local', () {
    late DirectorOversightStore store;

    setUp(() {
      store = DirectorOversightStore.instance;
      store.debugReset();
    });

    test(
      'Filtros calculados (workingWithoutFeedback, outdatedApprovals, flagged)',
      () {
        store.debugSeed(
          teachers: [
            const TeacherSummary(
              userId: 1,
              name: 'Bien',
              email: '',
              edits: 10,
              reviews: 5,
            ),
            const TeacherSummary(
              userId: 2,
              name: 'Sin Feedback',
              email: '',
              edits: 5,
              reviews: 0,
            ),
            const TeacherSummary(
              userId: 3,
              name: 'Vago',
              email: '',
              edits: 0,
              reviews: 0,
            ),
          ],
          verdicts: [
            const ContentVerdict(
              sectionId: 's1',
              status: 'aprobado',
              comment: '',
              outdated: false,
            ),
            const ContentVerdict(
              sectionId: 's2',
              status: 'aprobado',
              comment: '',
              outdated: true,
            ), // Outdated
            const ContentVerdict(
              sectionId: 's3',
              status: 'observado',
              comment: '',
              outdated: false,
            ), // Flagged
          ],
        );

        final noFeedback = store.workingWithoutFeedback;
        expect(noFeedback.length, 1);
        expect(
          noFeedback.first.name,
          'Sin Feedback',
        ); // Edita pero no tiene revisiones

        final outdated = store.outdatedApprovals;
        expect(outdated.length, 1);
        expect(outdated.first.sectionId, 's2');

        final flagged = store.flagged;
        expect(flagged.length, 1);
        expect(flagged.first.sectionId, 's3');
      },
    );

    test('verdictOf devuelve la revisión correcta considerando el curso', () {
      store.debugSeed(
        verdicts: [
          const ContentVerdict(
            sectionId: 's1',
            courseId: 10,
            status: 'aprobado',
            comment: '',
            outdated: false,
          ),
          const ContentVerdict(
            sectionId: 's1',
            courseId: 20,
            status: 'observado',
            comment: '',
            outdated: false,
          ),
        ],
      );

      expect(store.verdictOf('s1', courseId: 10)?.status, 'aprobado');
      expect(store.verdictOf('s1', courseId: 20)?.status, 'observado');
      expect(store.verdictOf('s2'), isNull);
    });
  });

  group('DirectorOversightStore - Peticiones de red', () {
    late DirectorOversightStore store;
    late FakeAuthStorage fakeAuth;
    late FakeApiService fakeApi;

    setUp(() {
      store = DirectorOversightStore.instance;
      store.debugReset();
      fakeAuth = FakeAuthStorage();
      fakeApi = FakeApiService();
    });

    test('refresh maneja error de sesión y 403', () async {
      // Sin sesión
      fakeAuth.dummyToken = null;
      store.debugUse(api: fakeApi, client: http.Client(), auth: fakeAuth);
      await store.refresh();
      expect(store.problem, 'Tu sesión no está iniciada. Vuelve a entrar.');

      // Con sesión pero 403
      fakeAuth.dummyToken = 'valid';
      final mockClient = MockClient((req) async => http.Response('', 403));
      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);
      await store.refresh();
      expect(
        store.problem,
        'Tu cuenta no tiene permiso para ver el seguimiento.',
      );
    });

    test('refresh carga datos correctamente (200 OK)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('teachers')) {
          return http.Response(
            '{"teachers": [{"user_id": 1, "nombre": "Docente 1", "edits": 5}]}',
            200,
          );
        }
        if (request.url.path.contains('content')) {
          return http.Response(
            '{"items": [{"section_id": "s1", "status": "aprobado"}]}',
            200,
          );
        }
        if (request.url.path.contains('courses')) {
          return http.Response(
            '{"courses": [{"id": 1, "title": "Curso 1", "is_general": false, "students": 10}]}',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);
      await store.refresh();

      expect(store.problem, isNull);
      expect(store.teachers.length, 1);
      expect(store.verdicts.length, 1);
      expect(store.courses.length, 1);
      expect(store.coursesSupported, true);
    });

    test('activityOf y reviewsOf parsean listas correctamente', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('activity')) {
          return http.Response(
            '{"items": [{"scope": "module", "target_id": "1", "review_outdated": false}]}',
            200,
          );
        }
        if (request.url.path.contains('reviews')) {
          return http.Response(
            '{"reviews": [{"score": 5, "comment": "Excelente"}]}',
            200,
          );
        }
        return http.Response('', 404);
      });
      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

      final activity = await store.activityOf(1);
      expect(activity.length, 1);
      expect(activity.first.scope, 'module');

      final reviews = await store.reviewsOf(1);
      expect(reviews.length, 1);
      expect(reviews.first.score, 5);
    });

    test(
      'review y judgeContent manejan errores con detail del backend',
      () async {
        final mockClient = MockClient((request) async {
          // Simulamos un error 400 devolviendo un JSON con 'detail'
          return http.Response('{"detail": "Faltan datos obligatorios"}', 400);
        });
        store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

        expect(
          () => store.review(userId: 1, score: 5, comment: ''),
          throwsA(
            isA<OversightException>().having(
              (e) => e.message,
              'message',
              'Faltan datos obligatorios',
            ),
          ),
        );

        expect(
          () =>
              store.judgeContent(sectionId: 's1', approved: true, comment: ''),
          throwsA(
            isA<OversightException>().having(
              (e) => e.message,
              'message',
              'Faltan datos obligatorios',
            ),
          ),
        );
      },
    );
  });
}
