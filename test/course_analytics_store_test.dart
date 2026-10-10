import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Ajusta estas rutas a las reales de tu proyecto
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';

// import 'package:flutter_code4all/course_analytics_store.dart'; // Importa tu archivo aquí

/// Fakes para simular dependencias sin usar librerías externas complejas
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
  group('Modelos de Analítica', () {
    test('SectionStats calcula fallos y precisión correctamente', () {
      const stats = SectionStats(
        sectionId: 's1',
        answered: 10,
        correct: 8,
        students: 5,
      );
      expect(stats.failed, 2);
      expect(stats.accuracy, 0.8);

      const emptyStats = SectionStats(
        sectionId: 's2',
        answered: 0,
        correct: 0,
        students: 0,
      );
      expect(emptyStats.accuracy, 0.0); // Evita división por cero
    });

    test('ActivityCompletionStats devuelve el label correcto', () {
      const reading = ActivityCompletionStats(
        sectionId: '1',
        activity: 'lectura',
        students: 5,
      );
      const unknown = ActivityCompletionStats(
        sectionId: '1',
        activity: 'otra_cosa',
        students: 5,
      );

      expect(reading.label, 'Lectura');
      expect(unknown.label, 'otra_cosa');
    });

    test('StudentStats identifica quién no ha empezado', () {
      const active = StudentStats(
        userId: 1,
        name: 'A',
        email: 'a@a.com',
        answered: 1,
        correct: 1,
        sectionsTouched: 1,
        activitiesDone: 1,
      );
      const lazy = StudentStats(
        userId: 2,
        name: 'B',
        email: 'b@b.com',
        answered: 0,
        correct: 0,
        sectionsTouched: 0,
        activitiesDone: 0,
      );

      expect(active.hasNotStarted, false);
      expect(lazy.hasNotStarted, true);
    });
  });

  group('CourseAnalyticsStore - Lógica de datos', () {
    late CourseAnalyticsStore store;

    setUp(() {
      store = CourseAnalyticsStore.instance;
      store.debugReset();
    });

    test('useCourse limpia los datos al cambiar de curso', () {
      store.debugSeed(totalAnswers: 100);
      expect(store.totalAnswers, 100);

      store.useCourse(42);
      expect(store.courseId, 42);
      expect(store.totalAnswers, 0); // Se limpió
    });

    test(
      'Propiedades calculadas (overallAccuracy, activeStudents, isEmpty)',
      () {
        store.debugSeed(
          sections: [
            const SectionStats(
              sectionId: 's1',
              answered: 10,
              correct: 5,
              students: 2,
            ), // 50%
            const SectionStats(
              sectionId: 's2',
              answered: 30,
              correct: 30,
              students: 5,
            ), // 100%
          ],
          students: [
            const StudentStats(
              userId: 1,
              name: 'A',
              email: '',
              answered: 1,
              correct: 1,
              sectionsTouched: 1,
              activitiesDone: 1,
            ),
            const StudentStats(
              userId: 2,
              name: 'B',
              email: '',
              answered: 0,
              correct: 0,
              sectionsTouched: 0,
              activitiesDone: 0,
            ),
          ],
          totalAnswers: 40,
          totalCompletions: 1,
        );

        // (5 + 30) / (10 + 30) = 35 / 40 = 0.875
        expect(store.overallAccuracy, 0.875);
        expect(store.activeStudents, 1); // Solo 1 ha empezado
        expect(store.isEmpty, false);
        expect(store.hasNoAnswers, false);
      },
    );

    test('hardestSections y slowestQuestions filtran y ordenan bien', () {
      store.debugSeed(
        sections: [
          const SectionStats(
            sectionId: 'muy_pocas_respuestas',
            answered: 1,
            correct: 0,
            students: 1,
          ), // accuracy 0, pero solo 1 respuesta
          const SectionStats(
            sectionId: 'dificil',
            answered: 10,
            correct: 2,
            students: 5,
          ), // accuracy 20%
          const SectionStats(
            sectionId: 'facil',
            answered: 10,
            correct: 9,
            students: 5,
          ), // accuracy 90%
        ],
        questions: [
          const QuestionStats(
            sectionId: 's1',
            activity: 'q1',
            questionIndex: 1,
            prompt: '',
            answered: 10,
            correct: 5,
            avgSeconds: 15.0,
          ),
          const QuestionStats(
            sectionId: 's1',
            activity: 'q2',
            questionIndex: 2,
            prompt: '',
            answered: 10,
            correct: 5,
            avgSeconds: 120.0,
          ), // La más lenta
        ],
      );

      final hardest = store.hardestSections(minAnswers: 3);
      expect(hardest.length, 2);
      expect(hardest.first.sectionId, 'dificil'); // Primero la de peor accuracy

      final slowest = store.slowestQuestions(minAnswers: 3);
      expect(slowest.first.avgSeconds, 120.0); // Ordenado descendente
    });
  });

  group('CourseAnalyticsStore - Peticiones de Red (refresh)', () {
    late CourseAnalyticsStore store;
    late FakeAuthStorage fakeAuth;
    late FakeApiService fakeApi;

    setUp(() {
      store = CourseAnalyticsStore.instance;
      store.debugReset();
      fakeAuth = FakeAuthStorage();
      fakeApi = FakeApiService();
    });

    test('Falla por falta de sesión (token vacío)', () async {
      fakeAuth.dummyToken = null;
      store.debugUse(api: fakeApi, client: http.Client(), auth: fakeAuth);

      await store.refresh();

      expect(store.problem, 'Tu sesión no está iniciada. Vuelve a entrar.');
      expect(store.isLoaded, true);
    });

    test('Maneja error de permisos (403 Forbidden)', () async {
      final mockClient = MockClient(
        (request) async => http.Response('Forbidden', 403),
      );
      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

      await store.refresh();

      expect(store.problem, 'Tu cuenta no tiene permiso para ver estos datos.');
    });

    test('Maneja otros errores HTTP (ej. 500)', () async {
      final mockClient = MockClient(
        (request) async => http.Response('Error', 500),
      );
      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

      await store.refresh();

      expect(store.problem, 'El servidor no devolvió los datos (500).');
    });

    test('Maneja fallo de red (Excepción)', () async {
      final mockClient = MockClient(
        (request) async => throw Exception('Red caída'),
      );
      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

      await store.refresh();

      expect(store.problem, 'No se pudo consultar el servidor.');
    });

    test('Carga datos exitosamente (200 OK)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('summary')) {
          return http.Response('''
            {
              "total_answers": 150,
              "total_completions": 50,
              "sections": [{"section_id": "intro", "answered": 10, "correct": 8, "students": 5}],
              "questions": [{"section_id": "intro", "activity": "quiz", "question_index": 0, "prompt": "Test", "answered": 10, "correct": 8, "avg_seconds": 12.5}],
              "completions": [{"section_id": "intro", "activity": "quiz", "students": 5}]
            }
          ''', 200);
        } else if (request.url.path.contains('students')) {
          return http.Response('''
            {
              "students": [
                {"user_id": 1, "nombre": "Ana", "correo": "ana@test.com", "answered": 5, "correct": 5, "sections_touched": 1, "activities_done": 2}
              ]
            }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      store.debugUse(api: fakeApi, client: mockClient, auth: fakeAuth);

      await store.refresh();

      expect(store.problem, isNull);
      expect(store.totalAnswers, 150);
      expect(store.sections.length, 1);
      expect(store.questions.length, 1);
      expect(store.students.length, 1);

      // Comprobación de funciones derivadas usando los datos de la red
      expect(store.completionsOf('intro')['quiz'], 5);
      expect(store.students.first.name, 'Ana');
    });
  });
}
