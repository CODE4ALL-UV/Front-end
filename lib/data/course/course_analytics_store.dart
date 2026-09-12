import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';

/// Cómo le está yendo a una sección del curso.
@immutable
class SectionStats {
  const SectionStats({
    required this.sectionId,
    required this.answered,
    required this.correct,
    required this.students,
    this.avgSeconds,
  });

  factory SectionStats.fromJson(Map<String, dynamic> json) => SectionStats(
    sectionId: json['section_id'] as String? ?? '',
    answered: (json['answered'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    students: (json['students'] as num?)?.toInt() ?? 0,
    avgSeconds: (json['avg_seconds'] as num?)?.toDouble(),
  );

  final String sectionId;
  final int answered;
  final int correct;
  final int students;

  /// Cuánto se tarda de media en responder, en segundos.
  ///
  /// Nulo cuando no hay tiempos medidos: lo registrado antes de que se
  /// midiera no tiene ninguno, y contarlo como cero mentiría.
  final double? avgSeconds;

  int get failed => answered - correct;

  /// Proporción de aciertos, de 0 a 1.
  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// El nombre que el docente reconoce, no el identificador interno.
  String get title =>
      PythonCourseCatalog.sectionById(sectionId)?.title ?? sectionId;

  /// A qué módulo pertenece, para agrupar.
  int get moduleNumber =>
      PythonCourseCatalog.sectionById(sectionId)?.moduleNumber ?? 0;
}

/// Cómo le está yendo a una pregunta concreta.
@immutable
class QuestionStats {
  const QuestionStats({
    required this.sectionId,
    required this.activity,
    required this.questionIndex,
    required this.prompt,
    required this.answered,
    required this.correct,
    this.avgSeconds,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) => QuestionStats(
    sectionId: json['section_id'] as String? ?? '',
    activity: json['activity'] as String? ?? '',
    questionIndex: (json['question_index'] as num?)?.toInt() ?? 0,
    prompt: json['prompt'] as String? ?? '',
    answered: (json['answered'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    avgSeconds: (json['avg_seconds'] as num?)?.toDouble(),
  );

  final String sectionId;
  final String activity;
  final int questionIndex;
  final String prompt;
  final int answered;
  final int correct;

  /// Media de segundos en contestarla, o nulo si no se midió.
  final double? avgSeconds;

  int get failed => answered - correct;
  double get accuracy => answered == 0 ? 0 : correct / answered;

  String get sectionTitle =>
      PythonCourseCatalog.sectionById(sectionId)?.title ?? sectionId;
}

/// Cuántos estudiantes han terminado una actividad concreta.
@immutable
class ActivityCompletionStats {
  const ActivityCompletionStats({
    required this.sectionId,
    required this.activity,
    required this.students,
  });

  factory ActivityCompletionStats.fromJson(Map<String, dynamic> json) =>
      ActivityCompletionStats(
        sectionId: json['section_id'] as String? ?? '',
        activity: json['activity'] as String? ?? '',
        students: (json['students'] as num?)?.toInt() ?? 0,
      );

  final String sectionId;
  final String activity;
  final int students;

  String get sectionTitle =>
      PythonCourseCatalog.sectionById(sectionId)?.title ?? sectionId;

  /// Nombre de la actividad tal y como lo ve el docente.
  String get label => switch (activity) {
    'lectura' => 'Lectura',
    'capsula' => 'Cápsula',
    'ejemplo' => 'Ejemplo',
    'ejercicio' => 'Ejercicio',
    'quiz' => 'Quiz',
    'evaluacion' => 'Evaluación final',
    'video' => 'Video',
    'laboratorio' => 'Laboratorio',
    _ => activity,
  };
}

/// Un estudiante y cómo le va.
@immutable
class StudentStats {
  const StudentStats({
    required this.userId,
    required this.name,
    required this.email,
    required this.answered,
    required this.correct,
    required this.sectionsTouched,
    required this.activitiesDone,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) => StudentStats(
    userId: (json['user_id'] as num?)?.toInt() ?? 0,
    name: json['nombre'] as String? ?? '',
    email: json['correo'] as String? ?? '',
    answered: (json['answered'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    sectionsTouched: (json['sections_touched'] as num?)?.toInt() ?? 0,
    activitiesDone: (json['activities_done'] as num?)?.toInt() ?? 0,
  );

  final int userId;
  final String name;
  final String email;
  final int answered;
  final int correct;
  final int sectionsTouched;

  /// Actividades terminadas: lecturas, videos, quiz… todo el curso.
  final int activitiesDone;

  int get failed => answered - correct;
  double get accuracy => answered == 0 ? 0 : correct / answered;

  /// Todavía no ha tocado nada del curso.
  ///
  /// Es la señal más útil de la lista: quien no aparece es quien no ha
  /// empezado, y ese es justo a quien hay que buscar.
  bool get hasNotStarted => answered == 0 && activitiesDone == 0;
}

/// Lo que el docente necesita saber del curso: qué se entiende y qué no.
///
/// Los datos salen de lo que responden los estudiantes de verdad. Si nadie ha
/// respondido todavía, aquí no hay nada, y las pantallas deben decirlo con
/// esas palabras en vez de enseñar ceros que parecen resultados.
class CourseAnalyticsStore extends ChangeNotifier {
  CourseAnalyticsStore._();

  static final CourseAnalyticsStore instance = CourseAnalyticsStore._();

  ApiService _api = ApiService();
  http.Client _client = http.Client();
  AuthStorage _auth = AuthStorage();

  static const Duration _timeout = Duration(seconds: 10);

  List<SectionStats> _sections = const [];
  List<QuestionStats> _questions = const [];
  List<StudentStats> _students = const [];
  List<ActivityCompletionStats> _completions = const [];

  int _totalAnswers = 0;
  int _totalCompletions = 0;
  bool _loading = false;
  bool _loaded = false;
  String? _problem;

  List<SectionStats> get sections => _sections;
  List<QuestionStats> get questions => _questions;
  List<StudentStats> get students => _students;
  List<ActivityCompletionStats> get completions => _completions;

  int get totalAnswers => _totalAnswers;
  int get totalCompletions => _totalCompletions;
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get problem => _problem;

  /// Nadie ha tocado nada del curso todavía.
  bool get isEmpty => _totalAnswers == 0 && _totalCompletions == 0;

  /// Nadie ha respondido preguntas, aunque quizá sí haya leído.
  ///
  /// Se distingue de [isEmpty] a propósito: un curso donde se lee pero no se
  /// responde no es un curso vacío, es uno donde nadie llega a los quiz.
  bool get hasNoAnswers => _totalAnswers == 0;

  /// Cuántos estudiantes han empezado, respondiendo o haciendo algo.
  int get activeStudents =>
      _students.where((student) => !student.hasNotStarted).length;

  /// Cuántos estudiantes terminaron cada actividad de una sección.
  Map<String, int> completionsOf(String sectionId) => {
    for (final item in _completions)
      if (item.sectionId == sectionId) item.activity: item.students,
  };

  /// Aciertos sobre el total, en todo el curso.
  double get overallAccuracy {
    var answered = 0;
    var correct = 0;
    for (final section in _sections) {
      answered += section.answered;
      correct += section.correct;
    }
    return answered == 0 ? 0 : correct / answered;
  }

  /// Las secciones ordenadas de la que peor va a la que mejor.
  ///
  /// Solo cuentan las que tienen respuestas suficientes: con dos respuestas
  /// sueltas, un 0 % no dice que el tema sea difícil, dice que casi nadie lo
  /// ha hecho.
  List<SectionStats> hardestSections({int minAnswers = 3}) {
    final useful = _sections
        .where((section) => section.answered >= minAnswers)
        .toList();
    useful.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return useful;
  }

  /// Las preguntas que más se fallan.
  List<QuestionStats> hardestQuestions({int minAnswers = 3, int take = 10}) {
    final useful = _questions
        .where((question) => question.answered >= minAnswers)
        .toList();
    useful.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return useful.take(take).toList();
  }

  /// Las preguntas que más tiempo cuesta responder.
  ///
  /// Es una señal distinta de fallarlas: una pregunta que casi todos aciertan
  /// pero que lleva un minuto suele estar mal redactada, no ser difícil.
  List<QuestionStats> slowestQuestions({int minAnswers = 3, int take = 5}) {
    final useful = _questions
        .where((q) => q.answered >= minAnswers && q.avgSeconds != null)
        .toList();
    useful.sort((a, b) => b.avgSeconds!.compareTo(a.avgSeconds!));
    return useful.take(take).toList();
  }

  Future<void> refresh() async {
    if (_loading) return;

    _loading = true;
    notifyListeners();

    try {
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) {
        _problem = 'Tu sesión no está iniciada. Vuelve a entrar.';
      } else {
        final headers = {'Authorization': 'Bearer $token'};

        final summary = await _client
            .get(
              Uri.parse(_api.buildUrl('/api/analytics/summary')),
              headers: headers,
            )
            .timeout(_timeout);

        final students = await _client
            .get(
              Uri.parse(_api.buildUrl('/api/analytics/students')),
              headers: headers,
            )
            .timeout(_timeout);

        if (summary.statusCode == 403 || students.statusCode == 403) {
          _problem = 'Tu cuenta no tiene permiso para ver estos datos.';
        } else if (summary.statusCode != 200 || students.statusCode != 200) {
          _problem =
              'El servidor no devolvió los datos (${summary.statusCode}).';
        } else {
          _applySummary(summary.body);
          _applyStudents(students.body);
          _problem = null;
        }
      }
    } catch (e) {
      _problem = 'No se pudo consultar el servidor.';
      debugPrint('Analítica del curso: $e');
    }

    _loaded = true;
    _loading = false;
    notifyListeners();
  }

  void _applySummary(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return;

    _totalAnswers = (decoded['total_answers'] as num?)?.toInt() ?? 0;

    _sections = [
      for (final item in (decoded['sections'] as List? ?? const []))
        if (item is Map) SectionStats.fromJson(Map<String, dynamic>.from(item)),
    ];

    _questions = [
      for (final item in (decoded['questions'] as List? ?? const []))
        if (item is Map)
          QuestionStats.fromJson(Map<String, dynamic>.from(item)),
    ];

    _totalCompletions = (decoded['total_completions'] as num?)?.toInt() ?? 0;
    _completions = [
      for (final item in (decoded['completions'] as List? ?? const []))
        if (item is Map)
          ActivityCompletionStats.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  void _applyStudents(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return;

    _students = [
      for (final item in (decoded['students'] as List? ?? const []))
        if (item is Map) StudentStats.fromJson(Map<String, dynamic>.from(item)),
    ];
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
    List<SectionStats> sections = const [],
    List<QuestionStats> questions = const [],
    List<StudentStats> students = const [],
    List<ActivityCompletionStats> completions = const [],
    int totalAnswers = 0,
    int totalCompletions = 0,
  }) {
    _sections = sections;
    _questions = questions;
    _students = students;
    _completions = completions;
    _totalAnswers = totalAnswers;
    _totalCompletions = totalCompletions;
    _loaded = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugReset() {
    _sections = const [];
    _questions = const [];
    _students = const [];
    _completions = const [];
    _totalAnswers = 0;
    _totalCompletions = 0;
    _loading = false;
    _loaded = false;
    _problem = null;
    _api = ApiService();
    _client = http.Client();
    _auth = AuthStorage();
  }
}
