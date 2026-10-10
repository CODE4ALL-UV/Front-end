import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/google_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

// IMPORTANTE: Ajusta estas rutas a tu proyecto real
// import 'package:tu_app/data/services/api_service.dart';
// import 'package:tu_app/data/services/google_auth_service.dart';
// import 'package:tu_app/data/models/auth_models.dart';

// 1. Creamos las clases Mock con Mocktail
class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockApiService extends Mock implements ApiService {}

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  setUpAll(() {
    // Registramos variables de entorno base para que dotenv no falle
    dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');
  });

  group('GoogleAuthService Tests', () {
    test('GoogleAuthException.toString() retorna el mensaje correcto', () {
      const ex = GoogleAuthException('Error de prueba');
      expect(ex.toString(), 'Error de prueba');
    });

    test(
      'Lanza GoogleAuthException si falta el Client ID en el .env',
      () async {
        // Simulamos un .env vacío
        dotenv.testLoad(fileInput: '');

        final service = GoogleAuthService();

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(
            isA<GoogleAuthException>().having(
              (e) => e.message,
              'message',
              contains('Falta el Google Client ID'),
            ),
          ),
        );
      },
    );

    test(
      'Lanza GoogleAuthCanceledException si el usuario cancela el login (cuenta null)',
      () async {
        dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

        final mockGoogle = MockGoogleSignIn();
        when(() => mockGoogle.signIn()).thenAnswer((_) async => null);

        final service = GoogleAuthService(mockGoogleSignIn: mockGoogle);

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(isA<GoogleAuthCanceledException>()),
        );
      },
    );

    test(
      'Lanza GoogleAuthException si los tokens obtenidos son nulos o vacíos',
      () async {
        dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

        // Simulamos una autenticación sin tokens
        final mockAuth = MockGoogleSignInAuthentication();
        when(() => mockAuth.accessToken).thenReturn('');
        when(() => mockAuth.idToken).thenReturn(null);

        final mockAccount = MockGoogleSignInAccount();
        when(
          () => mockAccount.authentication,
        ).thenAnswer((_) async => mockAuth);

        final mockGoogle = MockGoogleSignIn();
        when(() => mockGoogle.signIn()).thenAnswer((_) async => mockAccount);

        final service = GoogleAuthService(mockGoogleSignIn: mockGoogle);

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(
            isA<GoogleAuthException>().having(
              (e) => e.message,
              'message',
              contains('No se obtuvo ningún token'),
            ),
          ),
        );
      },
    );

    test('Retorna LoginResponse cuando el flujo de Google es exitoso', () async {
      dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

      final mockAuth = MockGoogleSignInAuthentication();
      when(() => mockAuth.accessToken).thenReturn('access_token_123');
      when(() => mockAuth.idToken).thenReturn('id_token_123');

      final mockAccount = MockGoogleSignInAccount();
      when(() => mockAccount.authentication).thenAnswer((_) async => mockAuth);

      final mockGoogle = MockGoogleSignIn();
      when(() => mockGoogle.signIn()).thenAnswer((_) async => mockAccount);

      final mockApi = MockApiService();
      const mockResponse = LoginResponse(
        accessToken: 'mi_jwt_token',
        tokenType: 'Bearer',
        userId: 1,
        email: 'test@test.com',
        nombre: 'Usuario Test',
        rol: 'estudiante',
      );

      // Simulamos que el ApiService procesa los tokens de Google y devuelve el LoginResponse
      when(
        () => mockApi.signInWithGoogle(
          accessToken: 'access_token_123',
          idToken: 'id_token_123',
        ),
      ).thenAnswer((_) async => mockResponse);

      final service = GoogleAuthService(
        apiService: mockApi,
        mockGoogleSignIn: mockGoogle,
      );
      final result = await service.signIn(context: MockBuildContext());

      expect(result.accessToken, 'mi_jwt_token');
      expect(result.email, 'test@test.com');
      verify(
        () => mockApi.signInWithGoogle(
          accessToken: 'access_token_123',
          idToken: 'id_token_123',
        ),
      ).called(1);
    });

    test('Relanza ApiException proveniente del ApiService', () async {
      dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

      final mockAuth = MockGoogleSignInAuthentication();
      when(() => mockAuth.accessToken).thenReturn('token');
      when(() => mockAuth.idToken).thenReturn('token');

      final mockAccount = MockGoogleSignInAccount();
      when(() => mockAccount.authentication).thenAnswer((_) async => mockAuth);

      final mockGoogle = MockGoogleSignIn();
      when(() => mockGoogle.signIn()).thenAnswer((_) async => mockAccount);

      final mockApi = MockApiService();
      // Simulamos que el backend rechaza el token
      when(
        () => mockApi.signInWithGoogle(accessToken: 'token', idToken: 'token'),
      ).thenThrow(
        const ApiException(
          statusCode: 401,
          message: 'Token de Google inválido',
        ),
      );

      final service = GoogleAuthService(
        apiService: mockApi,
        mockGoogleSignIn: mockGoogle,
      );

      await expectLater(
        () => service.signIn(context: MockBuildContext()),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Token de Google inválido',
          ),
        ),
      );
    });

    test(
      'Atrapa errores nativos/desconocidos y los envuelve en GoogleAuthException',
      () async {
        dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

        final mockGoogle = MockGoogleSignIn();
        // Simulamos un error interno del SDK de Google (como que no esté configurado el SHA-1 en Android)
        when(
          () => mockGoogle.signIn(),
        ).thenThrow(Exception('PlatformException: DEVELOPER_ERROR'));

        final service = GoogleAuthService(mockGoogleSignIn: mockGoogle);

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(
            isA<GoogleAuthException>().having(
              (e) => e.message,
              'message',
              contains('No se pudo abrir la autenticación real de Google'),
            ),
          ),
        );
      },
    );

    test(
      'Lanza GoogleAuthException si idToken está vacío pero accessToken es válido',
      () async {
        dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');

        final mockAuth = MockGoogleSignInAuthentication();
        when(() => mockAuth.accessToken).thenReturn('token_valido');
        when(
          () => mockAuth.idToken,
        ).thenReturn(''); // Forzamos el fallo en la segunda condición

        final mockAccount = MockGoogleSignInAccount();
        when(
          () => mockAccount.authentication,
        ).thenAnswer((_) async => mockAuth);

        final mockGoogle = MockGoogleSignIn();
        when(() => mockGoogle.signIn()).thenAnswer((_) async => mockAccount);

        final service = GoogleAuthService(mockGoogleSignIn: mockGoogle);

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(isA<GoogleAuthException>()),
        );
      },
    );

    test(
      'Instancia GoogleSignIn real si no se pasa el mock (cubre líneas de instanciación)',
      () async {
        dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=test_id');
        // Al no pasar el mock, forzamos que pase por la línea 47-51 original.
        // Inmediatamente lanzará la excepción final porque estamos en un entorno de pruebas sin interfaz nativa.
        final service = GoogleAuthService();

        await expectLater(
          () => service.signIn(context: MockBuildContext()),
          throwsA(
            isA<GoogleAuthException>().having(
              (e) => e.message,
              'message',
              contains('No se pudo abrir la autenticación real'),
            ),
          ),
        );
      },
    );
  });
}
