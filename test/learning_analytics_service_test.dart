import 'dart:convert';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/data/services/learning_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

// IMPORTANTE: Ajusta estas importaciones a las rutas reales de tu proyecto
// import 'package:flutter_code4all/data/services/api_service.dart';
// import 'package:flutter_code4all/data/services/auth_storage.dart';
// import 'package:flutter_code4all/data/services/learning_analytics_service.dart';
// import 'package:flutter_code4all/data/services/course_progress_store.dart';

class MockApiService extends Mock implements ApiService {}

class MockAuthStorage extends Mock implements AuthStorage {}

class MockHttpClient extends Mock
    implements http.Client {} // Solo para test de dispose

void main() {
  late MockApiService mockApi;
  late MockAuthStorage mockAuth;
  const testUrl = 'https://servidor.com';

  setUp(() {
    mockApi = MockApiService();
    mockAuth = MockAuthStorage();

    // Comportamiento por defecto del mock de API
    when(
      () => mockApi.buildUrl(any()),
    ).thenAnswer((inv) => '$testUrl${inv.positionalArguments.first}');
  });

  group('LearningAnalyticsService Tests', () {
    test('Instancia Singleton está disponible', () {
      expect(
        LearningAnalyticsService.instance,
        isA<LearningAnalyticsService>(),
      );
    });

    test('activityName mapea CourseActivityKind correctamente', () {
      expect(
        LearningAnalyticsService.activityName(CourseActivityKind.quiz),
        'quiz',
      );
      expect(
        LearningAnalyticsService.activityName(CourseActivityKind.evaluacion),
        'evaluacion',
      );
      expect(
        LearningAnalyticsService.activityName(CourseActivityKind.ejercicio),
        'ejercicio',
      );

      // NOTA: Reemplaza 'CourseActivityKind.teoria' por un valor real de tu enum
      // que no sea quiz, evaluacion o ejercicio para cubrir el caso " _ => null "
      // expect(LearningAnalyticsService.activityName(CourseActivityKind.teoria), null);
    });

    test(
      'recordAttempt retorna false si results está vacío o activityName es null',
      () async {
        final service = LearningAnalyticsService(api: mockApi, auth: mockAuth);

        final resultVacio = await service.recordAttempt(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
          prompts: [],
          results: [], // Array vacío detiene la ejecución tempranamente
        );
        expect(resultVacio, isFalse);
      },
    );

    test(
      'recordAttempt y recordCompletion retornan false si el token es nulo',
      () async {
        when(() => mockAuth.getToken()).thenAnswer((_) async => null);
        final service = LearningAnalyticsService(api: mockApi, auth: mockAuth);

        final resultAttempt = await service.recordAttempt(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
          prompts: ['Q1'],
          results: [true],
        );

        final resultCompletion = await service.recordCompletion(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
        );

        expect(resultAttempt, isFalse);
        expect(resultCompletion, isFalse);
      },
    );

    test(
      'recordAttempt envía datos correctamente y retorna true (200 OK)',
      () async {
        when(() => mockAuth.getToken()).thenAnswer((_) async => 'token123');

        final mockClient = MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token123');

          final body = jsonDecode(request.body);
          expect(body['section_id'], 'sec1');
          expect(body['activity'], 'quiz');

          // Verificamos el armado de los arrays
          final answers = body['answers'] as List;
          expect(answers.length, 2);
          expect(answers[0]['prompt'], 'P1');
          expect(answers[0]['correct'], true);
          expect(answers[0]['elapsed_ms'], 1500);

          // Verificamos manejo de asimetría de arrays (prompts faltantes y nulls)
          expect(answers[1]['prompt'], ''); // Al no haber prompt en el index 1
          expect(answers[1]['correct'], false);
          expect(
            answers[1].containsKey('elapsed_ms'),
            false,
          ); // Era null, no debe existir

          return http.Response('', 201);
        });

        final service = LearningAnalyticsService(
          api: mockApi,
          auth: mockAuth,
          client: mockClient,
        );
        final result = await service.recordAttempt(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
          prompts: ['P1'], // Solo 1 prompt para forzar la asimetría
          results: [true, false],
          elapsedMs: [1500, null], // Fuerza evaluación del != null
        );

        expect(result, isTrue);
      },
    );

    test(
      'recordCompletion envía datos correctamente y retorna true (200 OK)',
      () async {
        when(() => mockAuth.getToken()).thenAnswer((_) async => 'token123');

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body);
          expect(body['section_id'], 'sec2');
          expect(body.containsKey('activity'), true);
          return http.Response('', 200);
        });

        final service = LearningAnalyticsService(
          api: mockApi,
          auth: mockAuth,
          client: mockClient,
        );
        final result = await service.recordCompletion(
          sectionId: 'sec2',
          kind: CourseActivityKind.ejercicio,
        );

        expect(result, isTrue);
      },
    );

    test(
      'Los métodos manejan excepciones de red (Timeouts/SocketException) y devuelven false',
      () async {
        when(() => mockAuth.getToken()).thenAnswer((_) async => 'token123');

        // Forzamos un fallo interno
        final mockClient = MockClient((request) async {
          throw Exception('Sin conexión');
        });

        final service = LearningAnalyticsService(
          api: mockApi,
          auth: mockAuth,
          client: mockClient,
        );

        final resultAttempt = await service.recordAttempt(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
          prompts: ['Q'],
          results: [true],
        );

        final resultCompletion = await service.recordCompletion(
          sectionId: 'sec1',
          kind: CourseActivityKind.quiz,
        );

        // Los catch(e) deben capturarlo silenciosamente y devolver false
        expect(resultAttempt, isFalse);
        expect(resultCompletion, isFalse);
      },
    );

    test(
      'Los métodos devuelven false ante códigos HTTP de error (Ej: 500 o 400)',
      () async {
        when(() => mockAuth.getToken()).thenAnswer((_) async => 'token123');

        final mockClient = MockClient(
          (request) async => http.Response('Error', 500),
        );
        final service = LearningAnalyticsService(
          api: mockApi,
          auth: mockAuth,
          client: mockClient,
        );

        expect(
          await service.recordCompletion(
            sectionId: '1',
            kind: CourseActivityKind.quiz,
          ),
          isFalse,
        );
      },
    );

    test('dispose llama a client.close()', () {
      final mockHttpClient = MockHttpClient();
      final service = LearningAnalyticsService(
        api: mockApi,
        auth: mockAuth,
        client: mockHttpClient,
      );

      service.dispose();
      verify(() => mockHttpClient.close()).called(1);
    });
  });
}
