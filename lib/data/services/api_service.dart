import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_models.dart';

class ApiService {
  ApiService({String? baseUrl})
    : _baseUrl = (baseUrl ?? _defaultBaseUrl()).trim();

  final String _baseUrl;

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (io.Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  String buildUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$_baseUrl$normalizedPath';
  }

  Future<RegisterResponse> register({
    required String nombre,
    required String correo,
    required String password,
    int? tipoDiscapacidad,
    required String rol,
  }) async {
    final request = RegisterRequest(
      nombre: nombre,
      correo: correo,
      password: password,
      tipoDiscapacidad: tipoDiscapacidad,
      rol: rol,
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

  Future<LoginResponse> signInWithGoogle({
    String? accessToken,
    String? idToken,
  }) async {
    try {
      final body = <String, String>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        body['access_token'] = accessToken;
      }
      if (idToken != null && idToken.isNotEmpty) {
        body['id_token'] = idToken;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
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

  String resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    final normalized = url.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }

    if (normalized.startsWith('/')) {
      return buildUrl(normalized);
    }

    return buildUrl('/$normalized');
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
