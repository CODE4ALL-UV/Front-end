import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tipos de actividad que componen la ruta de aprendizaje de una sección.
enum CourseActivityKind {
  lectura,
  capsula,
  ejemplo,
  ejercicio,
  quiz,
  evaluacion,
  video,
  laboratorio,
}

extension CourseActivityKindLabel on CourseActivityKind {
  /// Nombre visible de la actividad.
  String get label => switch (this) {
    CourseActivityKind.lectura => 'Lectura',
    CourseActivityKind.capsula => 'Cápsula de conocimiento',
    CourseActivityKind.ejemplo => 'Ejemplo',
    CourseActivityKind.ejercicio => 'Ejercicio',
    CourseActivityKind.quiz => 'Quiz',
    CourseActivityKind.evaluacion => 'Evaluación final',
    CourseActivityKind.video => 'Video',
    CourseActivityKind.laboratorio => 'Laboratorio',
  };

  /// Descripción de una línea. Es también lo que anuncia el lector de pantalla.
  String get description => switch (this) {
    CourseActivityKind.lectura => 'Lee el contenido del tema paso a paso',
    CourseActivityKind.capsula => 'Un consejo breve que resume lo esencial',
    CourseActivityKind.ejemplo => 'Código comentado línea por línea',
    CourseActivityKind.ejercicio => 'Practica lo aprendido',
    CourseActivityKind.quiz => 'Comprueba lo que recuerdas',
    CourseActivityKind.evaluacion => 'Evaluación final del tema',
    CourseActivityKind.video => 'Video con transcripción escrita',
    CourseActivityKind.laboratorio => 'Escribe y ejecuta código',
  };

  /// Texto del botón que abre la actividad.
  String get actionLabel => switch (this) {
    CourseActivityKind.lectura => 'Leer',
    CourseActivityKind.capsula => 'Ver tip',
    CourseActivityKind.ejemplo => 'Ver ejemplo',
    CourseActivityKind.ejercicio => 'Practicar',
    CourseActivityKind.quiz => 'Comenzar',
    CourseActivityKind.evaluacion => 'Evaluarme',
    CourseActivityKind.video => 'Ver video',
    CourseActivityKind.laboratorio => 'Explorar',
  };

  String get storageKey => name;
}

/// Guarda qué actividades ha completado el estudiante.
///
/// Se mantiene en memoria para que la interfaz responda al instante y se
/// persiste en el almacenamiento seguro del dispositivo, de modo que el
/// progreso sobrevive al cierre de la app.
class CourseProgressStore extends ChangeNotifier {
  CourseProgressStore._();

  static final CourseProgressStore instance = CourseProgressStore._();

  static const _storageKey = 'course_progress_completed';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Set<String> _completed = <String>{};

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Carga el progreso guardado. Es seguro llamarlo varias veces.
  Future<void> load() async {
    if (_loaded) return;

    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _completed.addAll(decoded.whereType<String>());
        }
      }
    } catch (e) {
      // Un progreso que no se puede leer no debe impedir estudiar.
      debugPrint('No se pudo cargar el progreso del curso: $e');
    }

    _loaded = true;
    notifyListeners();
  }

  static String activityKey(String sectionId, CourseActivityKind kind) =>
      '$sectionId::${kind.storageKey}';

  bool isCompleted(String sectionId, CourseActivityKind kind) =>
      _completed.contains(activityKey(sectionId, kind));

  /// Cuántas de las actividades indicadas ya están completadas.
  int completedCount(String sectionId, List<CourseActivityKind> kinds) =>
      kinds.where((kind) => isCompleted(sectionId, kind)).length;

  Future<void> markCompleted(String sectionId, CourseActivityKind kind) async {
    final key = activityKey(sectionId, kind);
    if (!_completed.add(key)) return;

    notifyListeners();
    await _persist();

    // Todas las actividades pasan por aqui, asi que engancharse en este punto
    // registra el curso entero sin tener que tocar cada pantalla. Va sin
    // esperar: el estudiante ya vio que termino y no debe aguardar a que
    // viaje una estadistica.
    unawaited(_report?.call(sectionId, kind) ?? Future<void>.value());
  }

  /// A quien avisar cuando se termina una actividad.
  ///
  /// Se inyecta desde fuera para que el almacen no dependa de la red: asi se
  /// puede probar el progreso sin levantar ningun servidor.
  Future<void> Function(String sectionId, CourseActivityKind kind)? _report;

  void reportCompletionsTo(
    Future<void> Function(String sectionId, CourseActivityKind kind)? report,
  ) {
    _report = report;
  }

  Future<void> resetSection(
    String sectionId,
    List<CourseActivityKind> kinds,
  ) async {
    var changed = false;
    for (final kind in kinds) {
      changed |= _completed.remove(activityKey(sectionId, kind));
    }
    if (!changed) return;

    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_completed.toList()),
      );
    } catch (e) {
      debugPrint('No se pudo guardar el progreso del curso: $e');
    }
  }
}
