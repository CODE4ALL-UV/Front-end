import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';

/// Un docente visto por la dirección.
@immutable
class TeacherSummary {
  const TeacherSummary({
    required this.userId,
    required this.name,
    required this.email,
    required this.edits,
    required this.reviews,
    this.lastEdit,
    this.lastScore,
    this.avgScore,
  });

  factory TeacherSummary.fromJson(Map<String, dynamic> json) => TeacherSummary(
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    name: json['nombre'] as String? ?? '',
    email: json['correo'] as String? ?? '',
    edits: (json['edits'] as num?)?.toInt() ?? 0,
    reviews: (json['reviews'] as num?)?.toInt() ?? 0,
    lastEdit: DateTime.tryParse(json['last_edit'] as String? ?? ''),
    lastScore: (json['last_score'] as num?)?.toInt(),
    avgScore: (json['avg_score'] as num?)?.toDouble(),
  );

  final int userId;
  final String name;
  final String email;

  /// Secciones y módulos que ha editado.
  final int edits;
  final int reviews;
  final DateTime? lastEdit;

  /// Última nota recibida, o nulo si nunca se le ha valorado.
  final int? lastScore;
  final double? avgScore;

  /// Todavía no ha tocado nada del temario.
  bool get hasNotEdited => edits == 0;

  /// Nadie le ha dicho nunca cómo lo está haciendo.
  bool get neverReviewed => reviews == 0;
}

/// Algo que un docente cambió del temario.
@immutable
class TeacherEdit {
  const TeacherEdit({
    required this.scope,
    required this.targetId,
    required this.reviewOutdated,
    this.updatedAt,
    this.reviewStatus,
    this.reviewComment,
  });

  factory TeacherEdit.fromJson(Map<String, dynamic> json) => TeacherEdit(
    scope: json['scope'] as String? ?? '',
    targetId: json['target_id'] as String? ?? '',
    reviewOutdated: json['review_outdated'] == true,
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    reviewStatus: json['review_status'] as String?,
    reviewComment: json['review_comment'] as String?,
  );

  final String scope;
  final String targetId;
  final DateTime? updatedAt;

  final String? reviewStatus;
  final String? reviewComment;

  /// La revisión es anterior a este cambio, así que ya no dice nada de él.
  final bool reviewOutdated;

  /// El nombre que la dirección reconoce, no el identificador interno.
  String get title {
    if (scope == 'module') return 'Módulo $targetId (nombre)';
    return PythonCourseCatalog.sectionById(targetId)?.title ?? targetId;
  }
}

/// Lo que la dirección opina del contenido de una sección.
@immutable
class ContentVerdict {
  const ContentVerdict({
    required this.sectionId,
    required this.status,
    required this.comment,
    required this.outdated,
    this.reviewedAt,
  });

  factory ContentVerdict.fromJson(Map<String, dynamic> json) => ContentVerdict(
    sectionId: json['section_id'] as String? ?? '',
    status: json['status'] as String? ?? '',
    comment: json['comment'] as String? ?? '',
    outdated: json['outdated'] == true,
    reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
  );

  final String sectionId;

  /// `aprobado` u `observado`.
  final String status;
  final String comment;
  final DateTime? reviewedAt;

  /// El docente cambió la sección después de esta revisión.
  final bool outdated;

  bool get isApproved => status == 'aprobado';

  String get sectionTitle =>
      PythonCourseCatalog.sectionById(sectionId)?.title ?? sectionId;
}

/// Una valoración que la dirección hizo de un docente.
@immutable
class TeacherReview {
  const TeacherReview({
    required this.score,
    required this.comment,
    this.createdAt,
  });

  factory TeacherReview.fromJson(Map<String, dynamic> json) => TeacherReview(
    score: (json['score'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  final int score;
  final String comment;
  final DateTime? createdAt;
}

/// Algo impidió guardar una valoración o una revisión.
class OversightException implements Exception {
  const OversightException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// El seguimiento que la dirección hace del trabajo docente.
///
/// Junta tres cosas que se preguntan por separado: qué ha hecho cada docente,
/// si su contenido está revisado, y cómo se le ha valorado. Al tenerlas en un
/// solo sitio, la pantalla puede decir cosas que ninguna diría sola —por
/// ejemplo, que un docente lleva veinte ediciones y ninguna valoración.
class DirectorOversightStore extends ChangeNotifier {
  DirectorOversightStore._();

  static final DirectorOversightStore instance = DirectorOversightStore._();

  ApiService _api = ApiService();
  http.Client _client = http.Client();
  AuthStorage _auth = AuthStorage();

  static const Duration _timeout = Duration(seconds: 10);

  List<TeacherSummary> _teachers = const [];
  List<ContentVerdict> _verdicts = const [];

  bool _loading = false;
  bool _loaded = false;
  String? _problem;

  List<TeacherSummary> get teachers => _teachers;
  List<ContentVerdict> get verdicts => _verdicts;

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get problem => _problem;

  /// Docentes que trabajan pero a los que nadie ha dicho nada.
  ///
  /// Es la señal más útil de la pantalla: alguien que edita y nunca recibe
  /// respuesta acaba dejando de editar.
  List<TeacherSummary> get workingWithoutFeedback =>
      _teachers.where((t) => t.edits > 0 && t.neverReviewed).toList();

  /// Secciones aprobadas que el docente cambió después.
  ///
  /// Su "aprobado" ya no vale para el contenido que hay ahora.
  List<ContentVerdict> get outdatedApprovals =>
      _verdicts.where((v) => v.isApproved && v.outdated).toList();

  /// Secciones con observaciones pendientes de arreglar.
  List<ContentVerdict> get flagged =>
      _verdicts.where((v) => !v.isApproved).toList();

  ContentVerdict? verdictOf(String sectionId) {
    for (final verdict in _verdicts) {
      if (verdict.sectionId == sectionId) return verdict;
    }
    return null;
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      throw const OversightException(
        'Tu sesión no está iniciada. Vuelve a entrar.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> refresh() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      final headers = await _headers();

      final teachers = await _client
          .get(Uri.parse(_api.buildUrl('/api/oversight/teachers')), headers: headers)
          .timeout(_timeout);
      final content = await _client
          .get(Uri.parse(_api.buildUrl('/api/oversight/content')), headers: headers)
          .timeout(_timeout);

      if (teachers.statusCode == 403 || content.statusCode == 403) {
        _problem = 'Tu cuenta no tiene permiso para ver el seguimiento.';
      } else if (teachers.statusCode != 200 || content.statusCode != 200) {
        _problem = 'El servidor no devolvió los datos '
            '(${teachers.statusCode}).';
      } else {
        _teachers = _parseList(
          teachers.body,
          'teachers',
          TeacherSummary.fromJson,
        );
        _verdicts = _parseList(content.body, 'items', ContentVerdict.fromJson);
        _problem = null;
      }
    } on OversightException catch (e) {
      _problem = e.message;
    } catch (e) {
      _problem = 'No se pudo consultar el servidor.';
      debugPrint('Seguimiento de dirección: $e');
    }

    _loaded = true;
    _loading = false;
    notifyListeners();
  }

  List<T> _parseList<T>(
    String body,
    String key,
    T Function(Map<String, dynamic>) build,
  ) {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded[key] is! List) return const [];

    return [
      for (final item in decoded[key] as List)
        if (item is Map) build(Map<String, dynamic>.from(item)),
    ];
  }

  /// Lo que ha tocado un docente, en detalle.
  Future<List<TeacherEdit>> activityOf(int userId) async {
    final response = await _client
        .get(
          Uri.parse(_api.buildUrl('/api/oversight/teachers/$userId/activity')),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw OversightException(
        'No se pudo consultar su actividad (${response.statusCode}).',
      );
    }
    return _parseList(response.body, 'items', TeacherEdit.fromJson);
  }

  /// Las valoraciones que ha recibido, de la más nueva a la más vieja.
  Future<List<TeacherReview>> reviewsOf(int userId) async {
    final response = await _client
        .get(
          Uri.parse(_api.buildUrl('/api/oversight/reviews/$userId')),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw OversightException(
        'No se pudieron consultar sus valoraciones (${response.statusCode}).',
      );
    }
    return _parseList(response.body, 'reviews', TeacherReview.fromJson);
  }

  /// Guarda una valoración. El comentario es obligatorio.
  Future<void> review({
    required int userId,
    required int score,
    required String comment,
  }) async {
    final response = await _post(
      '/api/oversight/reviews',
      {'docente_id': userId, 'score': score, 'comment': comment},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OversightException(_detailOf(response.body, 'No se pudo guardar.'));
    }

    await refresh();
  }

  /// Aprueba u observa el contenido de una sección.
  Future<void> judgeContent({
    required String sectionId,
    required bool approved,
    required String comment,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse(_api.buildUrl('/api/oversight/content/$sectionId')),
            headers: await _headers(json: true),
            body: jsonEncode({
              'section_id': sectionId,
              'status': approved ? 'aprobado' : 'observado',
              'comment': comment,
            }),
          )
          .timeout(_timeout);
    } on OversightException {
      rethrow;
    } catch (_) {
      throw const OversightException('El servidor no responde.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OversightException(_detailOf(response.body, 'No se pudo guardar.'));
    }

    await refresh();
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      return await _client
          .post(
            Uri.parse(_api.buildUrl(path)),
            headers: await _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on OversightException {
      rethrow;
    } catch (_) {
      throw const OversightException('El servidor no responde.');
    }
  }

  /// Saca el mensaje que manda el servidor, que ya viene en castellano.
  String _detailOf(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  @visibleForTesting
  void debugUse({
    required ApiService api,
    required http.Client client,
    required AuthStorage auth,
  }) {
    _api = api;
    _client = client;
    _auth = auth;
  }

  @visibleForTesting
  void debugSeed({
    List<TeacherSummary> teachers = const [],
    List<ContentVerdict> verdicts = const [],
  }) {
    _teachers = teachers;
    _verdicts = verdicts;
    _loaded = true;
    _problem = null;
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _teachers = const [];
    _verdicts = const [];
    _loading = false;
    _loaded = false;
    _problem = null;
    _api = ApiService();
    _client = http.Client();
    _auth = AuthStorage();
  }
}
