import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';

/// Los cursos de quien ha entrado y el que tiene abierto ahora.
///
/// Cada docente tiene sus propios cursos y cada estudiante está en los de sus
/// docentes. Elegir uno aquí es lo que hace que el resto de la aplicación
/// —el temario editado, el progreso y las estadísticas— hable de ese curso y
/// no de otro.
///
/// Si el servidor todavía no conoce los cursos (el backend de antes, sin el
/// gateway), [supported] queda en `false` y la aplicación sigue como siempre:
/// un único curso para todos.
class MyCoursesStore extends ChangeNotifier {
  MyCoursesStore._();

  static final MyCoursesStore instance = MyCoursesStore._();

  ApiService _api = ApiService();
  http.Client _client = http.Client();
  AuthStorage _auth = AuthStorage();

  static const Duration _timeout = Duration(seconds: 10);

  List<CourseInfo> _courses = const [];
  int? _generalCourseId;
  CourseInfo? _active;
  bool? _supported;
  bool _loading = false;
  String? _problem;

  List<CourseInfo> get courses => _courses;
  CourseInfo? get active => _active;
  int? get generalCourseId => _generalCourseId;

  /// `true` si el servidor tiene cursos por docente, `false` si es el de
  /// antes, `null` mientras no se sepa.
  bool? get supported => _supported;
  bool get isLoading => _loading;
  String? get problem => _problem;

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _auth.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Uri _url(String path) => Uri.parse(_api.buildUrl(path));

  /// Pide al servidor los cursos de quien ha entrado.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _problem = null;
    notifyListeners();

    try {
      final response = await _client
          .get(_url('/api/courses/mine'), headers: await _headers())
          .timeout(_timeout);

      if (response.statusCode == 404) {
        // El backend de antes: no hay cursos, sigue el curso único.
        _supported = false;
        _courses = const [];
      } else if (response.statusCode == 401) {
        _problem = 'Tu sesión caducó. Vuelve a iniciar sesión.';
      } else if (response.statusCode != 200) {
        _problem =
            'El servidor no devolvió tus cursos (${response.statusCode}).';
      } else {
        final decoded = jsonDecode(responseText(response));
        _courses = [
          for (final item in (decoded['courses'] as List? ?? const []))
            if (item is Map)
              CourseInfo.fromJson(Map<String, dynamic>.from(item)),
        ];
        _generalCourseId = (decoded['general_course_id'] as num?)?.toInt();
        _supported = true;

        // Si el curso abierto cambió por fuera (otro nombre, otro código), se
        // queda la versión nueva.
        final current = _active;
        if (current != null) {
          _active = _courses.where((c) => c.id == current.id).firstOrNull;
        }
      }
    } catch (e) {
      _problem = 'No se pudo consultar tus cursos. Revisa tu conexión.';
      debugPrint('Mis cursos: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Abre un curso: a partir de aquí el temario, el progreso y las
  /// estadísticas son los de ese curso.
  ///
  /// El Curso general usa los caminos de siempre (sin id), que funcionan con
  /// cualquier versión del servidor, y el mismo progreso guardado de antes.
  Future<void> select(CourseInfo? course) async {
    _active = course;
    notifyListeners();

    final id = (course == null || course.isGeneral) ? null : course.id;
    CourseProgressStore.instance.useCourse(id);
    CourseAnalyticsStore.instance.useCourse(id);
    await CourseContentStore.instance.useCourse(id);
  }

  /// El estudiante entra a un curso con el código de su docente.
  Future<CourseInfo> join(String code) async {
    final course = await _send('POST', '/api/courses/join', {'code': code});
    await refresh();
    return course!;
  }

  /// Un curso nuevo del docente.
  ///
  /// Con [copyGeneral] empieza con lo ya editado en el Curso general en vez
  /// de con el temario de fábrica.
  Future<CourseInfo> create({
    required String title,
    String description = '',
    bool copyGeneral = false,
  }) async {
    final course = await _send('POST', '/api/courses', {
      'title': title,
      'description': description,
      if (copyGeneral && _generalCourseId != null)
        'copy_from': _generalCourseId,
    });
    await refresh();
    return course!;
  }

  /// Cambia el código: el anterior deja de servir para entrar.
  Future<CourseInfo> renewCode(CourseInfo course) async {
    final renewed = await _send('POST', '/api/courses/${course.id}/join-code');
    await refresh();
    return renewed!;
  }

  Future<void> leave(CourseInfo course) async {
    await _send('DELETE', '/api/courses/${course.id}/enrollment');
    if (_active?.id == course.id) await select(null);
    await refresh();
  }

  Future<void> delete(CourseInfo course) async {
    await _send('DELETE', '/api/courses/${course.id}');
    if (_active?.id == course.id) await select(null);
    await refresh();
  }

  Future<CourseInfo?> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final http.Response response;
    try {
      final headers = await _headers(json: body != null);
      final uri = _url(path);
      response = await switch (method) {
        'DELETE' => _client.delete(uri, headers: headers),
        _ => _client.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      }.timeout(_timeout);
    } catch (e) {
      throw const CourseActionException(
        'El servidor no responde. Vuelve a intentarlo en un momento.',
      );
    }

    final text = responseText(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CourseActionException(_detail(text, response.statusCode));
    }

    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (decoded is Map && decoded['id'] is num) {
      return CourseInfo.fromJson(Map<String, dynamic>.from(decoded));
    }
    return null;
  }

  static String _detail(String body, int status) {
    try {
      final detail = (jsonDecode(body) as Map)['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {}
    if (status == 401) return 'Tu sesión caducó. Vuelve a iniciar sesión.';
    return 'No se pudo completar (error $status).';
  }

  /// Al cerrar sesión: el siguiente que entre no hereda los cursos de nadie.
  void clear() {
    _courses = const [];
    _generalCourseId = null;
    _active = null;
    _supported = null;
    _problem = null;
    _loading = false;
    CourseProgressStore.instance.useCourse(null);
    CourseAnalyticsStore.instance.useCourse(null);
    CourseContentStore.instance.useCourse(null);
    notifyListeners();
  }

  @visibleForTesting
  void debugUse({ApiService? api, http.Client? client, AuthStorage? auth}) {
    if (api != null) _api = api;
    if (client != null) _client = client;
    if (auth != null) _auth = auth;
  }

  @visibleForTesting
  void debugReset() {
    _courses = const [];
    _generalCourseId = null;
    _active = null;
    _supported = null;
    _problem = null;
    _loading = false;
    _api = ApiService();
    _client = http.Client();
    _auth = AuthStorage();
  }
}

/// Algo impidió crear, unirse o salir de un curso. Trae el mensaje listo.
class CourseActionException implements Exception {
  const CourseActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
