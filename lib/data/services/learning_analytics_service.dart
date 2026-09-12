import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';

/// Manda al servidor lo que el estudiante acaba de responder.
///
/// Sin esto el docente no tiene nada que mirar: el progreso se guardaba solo
/// en el dispositivo del estudiante, así que nadie más lo veía nunca.
///
/// **Nunca estorba al estudiante.** Si el servidor no responde, el intento se
/// pierde y ya está: no se avisa, no se reintenta, no se bloquea la pantalla.
/// Perder una estadística es un incordio para el docente; cortarle el quiz a
/// alguien que está estudiando es mucho peor.
///
/// De cada respuesta se manda si se acertó, no cuál se eligió. Para saber qué
/// tema cuesta más no hace falta más, y no conviene guardar de las personas
/// más de lo necesario.
class LearningAnalyticsService {
  LearningAnalyticsService({
    ApiService? api,
    http.Client? client,
    AuthStorage? auth,
  }) : _api = api ?? ApiService(),
       _client = client ?? http.Client(),
       _auth = auth ?? AuthStorage();

  final ApiService _api;
  final http.Client _client;
  final AuthStorage _auth;

  static final LearningAnalyticsService instance = LearningAnalyticsService();

  /// Corto a propósito: esto pasa mientras el estudiante ve su resultado, y
  /// no debe hacerle esperar.
  static const Duration timeout = Duration(seconds: 6);

  /// Qué nombre tiene cada actividad para el servidor.
  static String? activityName(CourseActivityKind kind) => switch (kind) {
    CourseActivityKind.quiz => 'quiz',
    CourseActivityKind.evaluacion => 'evaluacion',
    CourseActivityKind.ejercicio => 'ejercicio',
    // Las demás no tienen respuestas que contar.
    _ => null,
  };

  /// Registra un intento. Devuelve `true` si el servidor lo guardó.
  ///
  /// [results] lleva un valor por pregunta, en el mismo orden en que se
  /// mostraron: `true` si se acertó.
  ///
  /// [elapsedMs] es cuánto tardó en contestar cada una. Puede venir vacío o
  /// con huecos: una pregunta sin tiempo se guarda sin él en lugar de con un
  /// cero, que ensuciaría la media.
  Future<bool> recordAttempt({
    required String sectionId,
    required CourseActivityKind kind,
    required List<String> prompts,
    required List<bool> results,
    List<int?> elapsedMs = const [],
  }) async {
    final activity = activityName(kind);
    if (activity == null || results.isEmpty) return false;

    try {
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) return false;

      final answers = [
        for (var i = 0; i < results.length; i++)
          {
            'question_index': i,
            'prompt': i < prompts.length ? prompts[i] : '',
            'correct': results[i],
            if (i < elapsedMs.length && elapsedMs[i] != null)
              'elapsed_ms': elapsedMs[i],
          },
      ];

      final response = await _client
          .post(
            Uri.parse(_api.buildUrl('/api/analytics/attempts')),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'section_id': sectionId,
              'activity': activity,
              'answers': answers,
            }),
          )
          .timeout(timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      // A propósito no se avisa: el estudiante no tiene nada que arreglar y
      // nada que perder. Queda en el registro por si hace falta mirarlo.
      debugPrint('No se pudo registrar el intento: $e');
      return false;
    }
  }

  /// Anota que el estudiante terminó una actividad.
  ///
  /// Vale para todas, también las que no tienen preguntas. Es lo que permite
  /// al docente saber hasta dónde ha llegado cada uno y no solo cómo le fue
  /// en los quiz: un tema con mal porcentaje puede ser difícil, o puede ser
  /// que solo lo hayan hecho tres personas.
  ///
  /// Igual que el registro de respuestas, nunca estorba: si falla, se pierde
  /// la anotación y el estudiante ni se entera.
  Future<bool> recordCompletion({
    required String sectionId,
    required CourseActivityKind kind,
  }) async {
    try {
      final token = await _auth.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await _client
          .post(
            Uri.parse(_api.buildUrl('/api/analytics/completions')),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'section_id': sectionId,
              'activity': kind.storageKey,
            }),
          )
          .timeout(timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('No se pudo anotar la actividad terminada: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}
