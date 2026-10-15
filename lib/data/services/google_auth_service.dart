import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart'; // <-- 1. Importa esto

import '../models/auth_models.dart';
import 'api_service.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthCanceledException implements Exception {
  const GoogleAuthCanceledException();
}

class GoogleAuthService {
  GoogleAuthService({
    ApiService? apiService,
    @visibleForTesting this.mockGoogleSignIn, // <-- 2. Agrega este parámetro})
  }) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  final GoogleSignIn? mockGoogleSignIn; // <-- 3. Agrega esta propiedad

  Future<LoginResponse> signIn({required BuildContext context}) async {
    final googleClientId =
        (dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ??
                dotenv.env['GOOGLE_CLIENT_ID'])
            ?.trim();

    if (googleClientId == null || googleClientId.isEmpty) {
      throw const GoogleAuthException(
        'Falta el Google Client ID. Agrega GOOGLE_SERVER_CLIENT_ID o GOOGLE_CLIENT_ID en el archivo .env del frontend.',
      );
    }

    try {
      final googleSignIn =
          mockGoogleSignIn ??
          GoogleSignIn(
            clientId: kIsWeb ? googleClientId : null,
            serverClientId: !kIsWeb ? googleClientId : null,
            scopes: const ['email', 'profile'],
          );

      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const GoogleAuthCanceledException();
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      final idToken = auth.idToken;

      if ((accessToken == null || accessToken.isEmpty) &&
          (idToken == null || idToken.isEmpty)) {
        throw const GoogleAuthException(
          'No se obtuvo ningún token de Google. Revisa la configuración OAuth y el Client ID.',
        );
      }

      return await _apiService.signInWithGoogle(
        accessToken: accessToken,
        idToken: idToken,
      );
    } on GoogleAuthCanceledException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw GoogleAuthException(
        'No se pudo abrir la autenticación real de Google. Verifica el Client ID y que localhost esté autorizado en Google Cloud Console. Detalle: $error',
      );
    }
  }
}
