import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

import 'course_content_json.dart';
import 'python_course_catalog.dart';

/// El temario tal y como hay que mostrarlo: el de fábrica, con encima lo que
/// el docente haya cambiado.
///
/// El curso completo sigue viviendo dentro de la aplicación. Este almacén solo
/// guarda **lo editado**, que es poco y llega del servidor. La consecuencia
/// importante es que si el servidor no responde el estudiante no se queda sin
/// curso: ve la versión original. Nunca una pantalla vacía.
///
/// Al terminar de cargar avisa, así que cualquier pantalla que lo escuche se
/// redibuja sola con el contenido nuevo. Eso es lo que hace que un cambio del
/// docente llegue al estudiante sin recompilar nada.
///
/// Cada docente edita sus propios cursos, así que lo editado es siempre de un
/// curso: el que se eligió con [useCourse]. Sin curso (null) se usa el de
/// siempre, el Curso general, que funciona con cualquier versión del servidor.
class CourseContentStore extends ChangeNotifier {
  CourseContentStore._();

  static final CourseContentStore instance = CourseContentStore._();

  /// Para las pruebas: permite inyectar un cliente y una dirección.
  @visibleForTesting
  CourseContentStore.forTest({ApiService? api, http.Client? client})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client();

  ApiService _api = ApiService();
  http.Client _client = http.Client();
  AuthStorage _auth = AuthStorage();

  static const Duration _timeout = Duration(seconds: 8);

  /// Clave `'section:m1-s1'` o `'module:1'` → contenido editado.
  final Map<String, Map<String, dynamic>> _edits = {};

  bool _loaded = false;
  bool _loading = false;
  String? _problem;

  int? _courseId;

  /// El curso cuyo temario se está mostrando. Null es el Curso general.
  int? get courseId => _courseId;

  /// Dónde viven las ediciones del curso abierto.
  String get _base => _courseId == null
      ? '/api/course/overrides'
      : '/api/courses/$_courseId/overrides';

  /// Cambia de curso: se olvida lo editado del anterior y se pide lo del nuevo.
  Future<void> useCourse(int? courseId) async {
    if (courseId == _courseId && _loaded) return;
    _courseId = courseId;
    _edits.clear();
    _loaded = false;
    _problem = null;
    notifyListeners();
    await refresh();
  }

  /// Ya se intentó cargar al menos una vez.
  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  /// Por qué no se pudo hablar con el servidor, si es que pasó.
  ///
  /// No es un error que deba frenar a nadie: el curso se ve igual. Sirve para
  /// avisar al docente de que lo que está viendo puede no ser lo último.
  String? get problem => _problem;

  bool get hasEdits => _edits.isNotEmpty;
  int get editCount => _edits.length;

  static String sectionKey(String sectionId) => 'section:$sectionId';
  static String moduleKey(int moduleNumber) => 'module:$moduleNumber';

  // --- leer ----------------------------------------------------------------

  /// Pide al servidor lo que el docente haya cambiado.
  ///
  /// Es seguro llamarlo a menudo: si ya hay una carga en marcha no lanza otra.
  Future<void> refresh() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    final requested = _courseId;
    try {
      // Los cursos de un docente piden sesión: solo los ven él, sus
      // estudiantes y la coordinación.
      final token = requested == null ? null : await _auth.getToken();
      final response = await _client
          .get(
            Uri.parse(_api.buildUrl(_base)),
            headers: {
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (requested != _courseId) {
        // Mientras llegaba la respuesta se cambió de curso: esto ya no vale.
      } else if (response.statusCode != 200) {
        _problem = 'El servidor respondió ${response.statusCode}.';
      } else {
        _apply(responseText(response));
        _problem = null;
      }
    } catch (e) {
      // Sin servidor se sigue viendo el curso de fábrica, que es justo el
      // motivo de guardar solo los cambios y no el curso entero.
      _problem = 'No se pudo consultar el contenido editado.';
      debugPrint('Contenido del curso: $e');
    }

    _loaded = true;
    _loading = false;
    notifyListeners();
  }

  void _apply(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['items'] is! List) return;

    _edits.clear();
    for (final item in decoded['items'] as List) {
      if (item is! Map) continue;
      final scope = item['scope'];
      final target = item['target_id'];
      final content = item['content'];
      if (scope is! String || target is! String || content is! Map) continue;

      _edits['$scope:$target'] = Map<String, dynamic>.from(content);
    }
  }

  /// Carga una sola vez. Las siguientes llamadas no hacen nada.
  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    await refresh();
  }

  // --- combinar ------------------------------------------------------------

  /// La sección tal y como debe verse, con los cambios del docente aplicados.
  ///
  /// Devuelve `null` solo si la sección no existe en el temario de fábrica:
  /// una edición nunca puede inventar una sección que no estaba.
  CourseSection? section(int moduleNumber, int sectionNumber) {
    final original = PythonCourseCatalog.section(moduleNumber, sectionNumber);
    if (original == null) return null;

    final edit = _edits[sectionKey(original.id)];
    if (edit == null) return original;

    try {
      return sectionFromJson(edit, original);
    } catch (e) {
      // Una edición ilegible no puede dejar al estudiante sin sección: se
      // enseña la original y se sigue.
      debugPrint('No se pudo leer la edición de ${original.id}: $e');
      return original;
    }
  }

  /// El nombre del módulo, con el cambio del docente si lo hay.
  String moduleTitle(int moduleNumber, String fallback) {
    final edit = _edits[moduleKey(moduleNumber)];
    final title = edit?['title'];
    return title is String && title.trim().isNotEmpty ? title : fallback;
  }

  /// Si esta sección tiene cambios del docente.
  bool isSectionEdited(String sectionId) =>
      _edits.containsKey(sectionKey(sectionId));

  /// Si el nombre de este módulo fue cambiado.
  bool isModuleEdited(int moduleNumber) =>
      _edits.containsKey(moduleKey(moduleNumber));

  /// Quién cambió esto por última vez, si se sabe.
  String? editedBy(String key) => _edits[key]?['__updated_by'] as String?;

  // --- escribir (solo docente) --------------------------------------------

  /// Guarda una sección editada.
  ///
  /// El servidor comprueba por su cuenta que quien guarda sea docente: no se
  /// fía del rol que diga la aplicación, porque el dispositivo podría mentir.
  Future<void> saveSection(CourseSection section) async {
    await _write(
      method: 'PUT',
      path: '$_base/section/${section.id}',
      body: {'content': sectionToJson(section)},
    );

    _edits[sectionKey(section.id)] = sectionToJson(section);
    notifyListeners();
  }

  /// Cambia el nombre de un módulo.
  Future<void> saveModuleTitle(int moduleNumber, String title) async {
    final content = {'title': title};
    await _write(
      method: 'PUT',
      path: '$_base/module/$moduleNumber',
      body: {'content': content},
    );

    _edits[moduleKey(moduleNumber)] = content;
    notifyListeners();
  }

  /// Devuelve una sección a su versión de fábrica.
  ///
  /// No borra nada del curso: quita la edición, con lo que vuelve a verse el
  /// material original. Por eso se puede deshacer sin miedo.
  Future<void> revertSection(String sectionId) async {
    await _write(
      method: 'DELETE',
      path: '$_base/section/$sectionId',
    );

    _edits.remove(sectionKey(sectionId));
    notifyListeners();
  }

  Future<void> revertModuleTitle(int moduleNumber) async {
    await _write(
      method: 'DELETE',
      path: '$_base/module/$moduleNumber',
    );

    _edits.remove(moduleKey(moduleNumber));
    notifyListeners();
  }

  Future<void> _write({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      throw const CourseEditException(
        'Tu sesión no está iniciada. Vuelve a entrar para poder editar.',
      );
    }

    final uri = Uri.parse(_api.buildUrl(path));
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    final http.Response response;
    try {
      response = method == 'DELETE'
          ? await _client.delete(uri, headers: headers).timeout(_timeout)
          : await _client
                .put(uri, headers: headers, body: jsonEncode(body))
                .timeout(_timeout);
    } catch (e) {
      throw const CourseEditException(
        'No se pudo guardar: el servidor no responde. '
        'Tu texto sigue en pantalla, vuelve a intentarlo.',
      );
    }

    if (response.statusCode == 401) {
      throw const CourseEditException(
        'Tu sesión caducó. Vuelve a iniciar sesión para seguir editando.',
      );
    }
    if (response.statusCode == 403) {
      throw CourseEditException(
        _courseId == null
            ? 'El curso general solo lo edita la coordinación. Edita uno de '
                  'tus cursos.'
            : 'Solo el docente de este curso puede editarlo.',
      );
    }
    if (response.statusCode == 413) {
      throw const CourseEditException(
        'Esta sección es demasiado grande para guardarla. Acorta algún texto.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CourseEditException(
        'No se pudo guardar (error ${response.statusCode}).',
      );
    }
  }

  @visibleForTesting
  void debugSeed(Map<String, Map<String, dynamic>> edits) {
    _edits
      ..clear()
      ..addAll(edits);
    _loaded = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _edits.clear();
    _courseId = null;
    _loaded = false;
    _loading = false;
    _problem = null;
    _api = ApiService();
    _client = http.Client();
    _auth = AuthStorage();
  }

  @visibleForTesting
  void debugUse({
    required ApiService api,
    required http.Client client,
    AuthStorage? auth,
  }) {
    _api = api;
    _client = client;
    if (auth != null) _auth = auth;
  }
}

/// Algo impidió guardar un cambio del docente.
///
/// Lleva un mensaje ya escrito para enseñar en pantalla: al docente hay que
/// decirle qué pasó con su texto, no un código de error.
class CourseEditException implements Exception {
  const CourseEditException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El cuerpo de la respuesta en UTF-8, que es como lo manda el servidor. Si
/// no lo fuera (una respuesta de prueba, por ejemplo), el texto tal cual.
String responseText(http.Response response) {
  try {
    return utf8.decode(response.bodyBytes);
  } on FormatException {
    return response.body;
  }
}
