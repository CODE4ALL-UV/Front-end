import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_models.dart';

class ApiService {
  ApiService({String? baseUrl})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8000',
          );

  final String _baseUrl;

  Future<RegisterResponse> register({
    required String nombre,
    required String correo,
    required String password,
    int? tipoDiscapacidad,
  }) async {
    final request = RegisterRequest(
      nombre: nombre,
      correo: correo,
      password: password,
      tipoDiscapacidad: tipoDiscapacidad,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return RegisterResponse.fromJson(jsonDecode(response.body));
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response.body),
      );
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }

      throw ApiException(statusCode: null, message: _connectionErrorMessage());
    }
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response.body),
      );
    } catch (error) {
      if (error is ApiException) {
        rethrow;
      }

      throw ApiException(statusCode: null, message: _connectionErrorMessage());
    }
  }

  Future<LoginResponse> signInWithGoogle({required String idToken}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractMessage(response.body),
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(statusCode: null, message: _connectionErrorMessage());
    }
  }

  String _connectionErrorMessage() {
    return 'No se pudo conectar con el servidor. Verifica que el backend esté corriendo en $_baseUrl y que la ruta /api/auth/login o /api/auth/register esté disponible.';
  }

  String _extractMessage(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic> && decoded.containsKey('detail')) {
        return decoded['detail'].toString();
      }
      return 'Ocurrió un error inesperado';
    } catch (_) {
      return 'Ocurrió un error inesperado';
    }
  }
}
