import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_models.dart';

class ApiService {
  ApiService({String? baseUrl, http.Client? client})
    : _baseUrl = (baseUrl ?? _defaultBaseUrl()).trim(),
      _client = client ?? http.Client(); // <--- AGREGA ESTO;

  final String _baseUrl;
  final http.Client _client; // <--- AGREGA ESTO

  /// La dirección del servidor, sin barra al final.
  String get baseUrl => _baseUrl;

  /// Dirección del backend cuando nadie dice otra cosa.
  ///
  /// En producción se fija al compilar:
  ///
  ///     flutter build web --dart-define=BACKEND_URL=https://tu-api.onrender.com
  ///
  /// Sin eso, la aplicación desplegada apuntaría a `127.0.0.1`, que es el
  /// ordenador de quien la abre, no el servidor. Funcionaría en tu máquina y
  /// en ninguna otra.
  static const String _configuredUrl = String.fromEnvironment('BACKEND_URL');

  static String _defaultBaseUrl() {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;

    // En desarrollo, cada plataforma llega al servidor local por su camino.
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // El emulador de Android ve el ordenador anfitrión en esta dirección.
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
    String? codigoInvitacion,
  }) async {
    final request = RegisterRequest(
      nombre: nombre,
      correo: correo,
      password: password,
      tipoDiscapacidad: tipoDiscapacidad,
      rol: rol,
      codigoInvitacion: codigoInvitacion,
    );

    try {
      final response = await _client.post(
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
      final response = await _client.post(
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

  Future<List<dynamic>> getStudents({required String bearerToken}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/director/students'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body) as List);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(response.body),
    );
  }

  Future<List<dynamic>> getPerformances({required String bearerToken}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/director/performances'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body) as List);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(response.body),
    );
  }

  Future<List<dynamic>> getPerformancesAggregate({
    required String bearerToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/director/performances/aggregate'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body) as List);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(response.body),
    );
  }

  Future<List<dynamic>> getPerformancesAverage({
    required String bearerToken,
  }) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/director/performances/average'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
    );

    if (response.statusCode == 200) {
      return List<dynamic>.from(jsonDecode(response.body) as List);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(response.body),
    );
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

      final response = await _client.post(
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

  /// Entrar o registrarse con el código que devuelve Facebook.
  Future<LoginResponse> signInWithFacebook({
    required String code,
    required String redirectUri,
  }) async {
    final body = await _postJson(
      '/api/auth/facebook',
      {'code': code, 'redirect_uri': redirectUri},
      notFound:
          'El inicio con Facebook todavía no está disponible en el servidor.',
    );
    return LoginResponse.fromJson(body);
  }

  /// Pide el correo con el enlace para cambiar la contraseña.
  ///
  /// Devuelve lo que dice el servidor, que es lo mismo haya o no una cuenta
  /// con ese correo.
  Future<String> requestPasswordReset(String email) async {
    final body = await _postJson(
      '/api/auth/password/forgot',
      {'correo': email},
      notFound:
          'La recuperación de contraseña todavía no está disponible en el '
          'servidor.',
    );
    return (body['detail'] ?? '').toString();
  }

  /// Guarda la contraseña nueva con el token del enlace del correo.
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    final body = await _postJson(
      '/api/auth/password/reset',
      {'token': token, 'password': password},
      notFound:
          'La recuperación de contraseña todavía no está disponible en el '
          'servidor.',
    );
    return (body['detail'] ?? '').toString();
  }

  /// Un POST con JSON que devuelve el JSON de la respuesta.
  ///
  /// [notFound] es lo que se dice si el servidor no conoce la ruta: pasa con
  /// el servidor de antes, que no tiene las funciones nuevas. Sin él se vería
  /// un «Not Found» que no explica nada.
  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload, {
    required String notFound,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse(buildUrl(path)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw ApiException(statusCode: null, message: _connectionErrorMessage());
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
      return const {};
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: response.statusCode == 404
          ? notFound
          : _extractMessage(utf8.decode(response.bodyBytes)),
    );
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
