import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen_dark.dart';

import 'section_capsule_screen.dart';
import 'section_example_screen.dart';
import 'section_exercise_screen.dart';
import 'section_quiz_screen.dart';
import 'section_reading_screen.dart';
import 'section_video_screen.dart';

/// Los cuatro colores de una actividad: claro y oscuro, fondo y primer plano.
@immutable
class _ActivityColor {
  const _ActivityColor({
    required this.lightForeground,
    required this.lightBackground,
    required this.darkForeground,
    required this.darkBackground,
  });

  final Color lightForeground;
  final Color lightBackground;
  final Color darkForeground;
  final Color darkBackground;
}

/// Decide qué actividades tiene una sección y abre la pantalla de cada una.
///
/// Es el único lugar que conoce la correspondencia entre un tipo de actividad
/// y su pantalla, así que agregar una actividad nueva se hace aquí y no en las
/// seis pantallas de módulo.
abstract final class SectionActivityLauncher {
  /// Orden pedagógico de la ruta: primero leer, después entender con un
  /// ejemplo, luego practicar y por último evaluarse.
  static const List<CourseActivityKind> _order = [
    CourseActivityKind.lectura,
    CourseActivityKind.capsula,
    CourseActivityKind.ejemplo,
    CourseActivityKind.ejercicio,
    CourseActivityKind.video,
    CourseActivityKind.quiz,
    CourseActivityKind.laboratorio,
    CourseActivityKind.evaluacion,
  ];

  /// Las actividades disponibles de la sección, en orden.
  static List<CourseActivityKind> activitiesFor(CourseSection section) {
    return [
      for (final kind in _order)
        if (_isAvailable(section, kind)) kind,
    ];
  }

  static bool _isAvailable(CourseSection section, CourseActivityKind kind) =>
      switch (kind) {
        CourseActivityKind.lectura => section.reading != null,
        CourseActivityKind.capsula => section.capsule != null,
        CourseActivityKind.ejemplo => section.example != null,
        CourseActivityKind.ejercicio =>
          section.exercise != null && !section.exercise!.isEmpty,
        CourseActivityKind.video => section.videos.isNotEmpty,
        CourseActivityKind.quiz => section.quiz.isNotEmpty,
        CourseActivityKind.evaluacion => section.finalEvaluation.isNotEmpty,
        CourseActivityKind.laboratorio => section.hasLaboratory,
      };

  /// Icono de cada actividad. Acompaña siempre a la etiqueta de texto.
  static IconData iconFor(CourseActivityKind kind) => switch (kind) {
    CourseActivityKind.lectura => Icons.menu_book,
    CourseActivityKind.capsula => Icons.lightbulb,
    CourseActivityKind.ejemplo => Icons.terminal,
    CourseActivityKind.ejercicio => Icons.extension,
    CourseActivityKind.video => Icons.smart_display,
    CourseActivityKind.quiz => Icons.quiz,
    CourseActivityKind.laboratorio => Icons.science,
    CourseActivityKind.evaluacion => Icons.assignment_turned_in,
  };

  /// Color con el que se pinta el icono de cada actividad.
  ///
  /// Cada tipo de actividad tiene su propio color para que la ruta se lea de
  /// un vistazo. El color nunca va solo: siempre lo acompañan el icono y la
  /// etiqueta de texto, así que la ruta sigue siendo legible con daltonismo o
  /// en escala de grises.
  static ({Color foreground, Color background}) colorsFor(
    BuildContext context,
    CourseActivityKind kind,
  ) {
    final isDark = VisualThemeController.resolveIsDark(context);
    final entry = _activityColors[kind]!;
    return isDark
        ? (foreground: entry.darkForeground, background: entry.darkBackground)
        : (
            foreground: entry.lightForeground,
            background: entry.lightBackground,
          );
  }

  static const Map<CourseActivityKind, _ActivityColor> _activityColors = {
    CourseActivityKind.lectura: _ActivityColor(
      lightForeground: Color(0xFF0B5FC2),
      lightBackground: Color(0xFFE2EEFC),
      darkForeground: Color(0xFF8CBCF8),
      darkBackground: Color(0xFF16304B),
    ),
    CourseActivityKind.capsula: _ActivityColor(
      lightForeground: Color(0xFF8A5A00),
      lightBackground: Color(0xFFFDF0D8),
      darkForeground: Color(0xFFF2C572),
      darkBackground: Color(0xFF3B2C0F),
    ),
    CourseActivityKind.ejemplo: _ActivityColor(
      lightForeground: Color(0xFF0C6B58),
      lightBackground: Color(0xFFDDF3ED),
      darkForeground: Color(0xFF6FD6BD),
      darkBackground: Color(0xFF0E3B33),
    ),
    CourseActivityKind.ejercicio: _ActivityColor(
      lightForeground: Color(0xFF7A3AA0),
      lightBackground: Color(0xFFF2E6FA),
      darkForeground: Color(0xFFCB9DEC),
      darkBackground: Color(0xFF32204A),
    ),
    CourseActivityKind.video: _ActivityColor(
      lightForeground: Color(0xFFB3261E),
      lightBackground: Color(0xFFFBE6E3),
      darkForeground: Color(0xFFF3ABA4),
      darkBackground: Color(0xFF3E1B17),
    ),
    CourseActivityKind.quiz: _ActivityColor(
      lightForeground: Color(0xFF9A4B00),
      lightBackground: Color(0xFFFFEBD9),
      darkForeground: Color(0xFFF4B375),
      darkBackground: Color(0xFF40260E),
    ),
    CourseActivityKind.laboratorio: _ActivityColor(
      lightForeground: Color(0xFF15683A),
      lightBackground: Color(0xFFDFF3E7),
      darkForeground: Color(0xFF82D9A2),
      darkBackground: Color(0xFF11331F),
    ),
    CourseActivityKind.evaluacion: _ActivityColor(
      lightForeground: Color(0xFF1F4C8F),
      lightBackground: Color(0xFFE3ECFA),
      darkForeground: Color(0xFF9CC0F0),
      darkBackground: Color(0xFF1A2E4A),
    ),
  };

  /// Detalle extra que se muestra bajo el nombre de la actividad.
  static String detailFor(CourseSection section, CourseActivityKind kind) =>
      switch (kind) {
        CourseActivityKind.lectura =>
          '${section.readingPageCount} páginas de lectura',
        CourseActivityKind.quiz => '${section.quiz.length} preguntas',
        CourseActivityKind.evaluacion =>
          '${section.finalEvaluation.length} preguntas',
        CourseActivityKind.ejercicio => _exerciseDetail(section),
        CourseActivityKind.ejemplo => 'Código explicado línea por línea',
        CourseActivityKind.video => _videoDetail(section),
        CourseActivityKind.capsula =>
          '${section.capsule?.tips.length ?? 0} consejos clave',
        CourseActivityKind.laboratorio => 'Consola interactiva de Python',
      };

  static String _videoDetail(CourseSection section) {
    final count = section.videos.length;
    final plural = count == 1 ? 'video' : 'videos';
    return '$count $plural con subtítulos y señas';
  }

  static String _exerciseDetail(CourseSection section) {
    final exercise = section.exercise;
    if (exercise == null) return '';
    final total = exercise.pairs.length + exercise.questions.length;
    return '$total actividades de práctica';
  }

  /// Abre la actividad y devuelve `true` si el estudiante la completó.
  static Future<bool> open(
    BuildContext context,
    CourseModule module,
    CourseSection section,
    CourseActivityKind kind,
  ) async {
    final screen = _screenFor(context, module, section, kind);
    if (screen == null) return false;

    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => screen));

    // El laboratorio es una consola libre: no hay respuesta correcta que
    // comprobar, asi que no puede decir por si mismo si se "supero". Se da
    // por hecha al volver de ella. Sin esto una seccion con laboratorio nunca
    // llegaba al cien por cien, por mucho que el estudiante lo usara.
    if (kind == CourseActivityKind.laboratorio) {
      await CourseProgressStore.instance.markCompleted(section.id, kind);
      return true;
    }

    return result ?? false;
  }

  static Widget? _screenFor(
    BuildContext context,
    CourseModule module,
    CourseSection section,
    CourseActivityKind kind,
  ) {
    switch (kind) {
      case CourseActivityKind.lectura:
        return SectionReadingScreen(module: module, section: section);

      case CourseActivityKind.capsula:
        return SectionCapsuleScreen(module: module, section: section);

      case CourseActivityKind.ejemplo:
        return SectionExampleScreen(module: module, section: section);

      case CourseActivityKind.ejercicio:
        return SectionExerciseScreen(module: module, section: section);

      case CourseActivityKind.video:
        return SectionVideoScreen(module: module, section: section);

      case CourseActivityKind.quiz:
        return SectionQuizScreen(
          module: module,
          section: section,
          questions: section.quiz,
          activityKind: CourseActivityKind.quiz,
          activityLabel: 'Quiz',
          activityIcon: Icons.help_outline,
          introTitle: 'Quiz de repaso',
          introBody:
              'Responde para comprobar qué recuerdas de la lectura. Puedes '
              'reintentarlo las veces que quieras.',
        );

      case CourseActivityKind.evaluacion:
        return SectionQuizScreen(
          module: module,
          section: section,
          questions: section.finalEvaluation,
          activityKind: CourseActivityKind.evaluacion,
          activityLabel: 'Evaluación final',
          activityIcon: Icons.assignment_turned_in_outlined,
          introTitle: 'Evaluación final de la sección',
          introBody:
              'Necesitas acertar al menos el 60 por ciento para superarla. '
              'Tras cada respuesta verás la explicación.',
        );

      case CourseActivityKind.laboratorio:
        return VisualThemeController.resolveIsDark(context)
            ? const LaboratoryConsoleScreenDark()
            : const LaboratoryConsoleScreen();
    }
  }
}
