import 'package:flutter/material.dart';

// lectura: azul violeta OK
// capsula: amarillo verde OK (Retroalimentación, Ayudas, Tips, Buenas Prácticas)
// ejemplo: amarillo naranja OK
// ejercicio: violeta OK
// video: rojo violeta OK
// quiz: café OK
// laboratorio: azul verde OK
// evaluacion final: rojo naranja OK
// Omitidos: Glosario, Diccionario de LSC, Diagramas de flujo, Glosario interactivo, Califiaciones
enum ActivityThemeTone {
  reading,
  nugget,
  example,
  exercise,
  video,
  quiz,
  lab,
  finalEvaluation,
}

class ActivityTheme extends ThemeExtension<ActivityTheme> {
  final Color readingBackground;
  final Color readingForeground;
  final Color nuggetBackground;
  final Color nuggetForeground;
  final Color exampleBackground;
  final Color exampleForeground;
  final Color exerciseBackground;
  final Color exerciseForeground;
  final Color videoBackground;
  final Color videoForeground;
  final Color quizBackground;
  final Color quizForeground;
  final Color labBackground;
  final Color labForeground;
  final Color finalEvaluationBackground;
  final Color finalEvaluationForeground;

  const ActivityTheme({
    required this.readingBackground,
    required this.readingForeground,
    required this.nuggetBackground,
    required this.nuggetForeground,
    required this.exampleBackground,
    required this.exampleForeground,
    required this.exerciseBackground,
    required this.exerciseForeground,
    required this.videoBackground,
    required this.videoForeground,
    required this.quizBackground,
    required this.quizForeground,
    required this.labBackground,
    required this.labForeground,
    required this.finalEvaluationBackground,
    required this.finalEvaluationForeground,
  });

  ({Color background, Color foreground}) tone(ActivityThemeTone tone) =>
      switch (tone) {
        ActivityThemeTone.reading => (
          background: readingBackground,
          foreground: readingForeground,
        ),
        ActivityThemeTone.nugget => (
          background: nuggetBackground,
          foreground: nuggetForeground,
        ),
        ActivityThemeTone.example => (
          background: exampleBackground,
          foreground: exampleForeground,
        ),
        ActivityThemeTone.exercise => (
          background: exerciseBackground,
          foreground: exerciseForeground,
        ),
        ActivityThemeTone.video => (
          background: videoBackground,
          foreground: videoForeground,
        ),
        ActivityThemeTone.quiz => (
          background: quizBackground,
          foreground: quizForeground,
        ),
        ActivityThemeTone.lab => (
          background: labBackground,
          foreground: labForeground,
        ),
        ActivityThemeTone.finalEvaluation => (
          background: finalEvaluationBackground,
          foreground: finalEvaluationForeground,
        ),
      };

  @override
  ActivityTheme copyWith({
    Color? readingBackground,
    Color? readingForeground,
    Color? nuggetBackground,
    Color? nuggetForeground,
    Color? exampleBackground,
    Color? exampleForeground,
    Color? exerciseBackground,
    Color? exerciseForeground,
    Color? videoBackground,
    Color? videoForeground,
    Color? quizBackground,
    Color? quizForeground,
    Color? labBackground,
    Color? labForeground,
    Color? finalEvaluationBackground,
    Color? finalEvaluationForeground,
  }) {
    return ActivityTheme(
      readingBackground: readingBackground ?? this.readingBackground,
      readingForeground: readingForeground ?? this.readingForeground,
      nuggetBackground: nuggetBackground ?? this.nuggetBackground,
      nuggetForeground: nuggetForeground ?? this.nuggetForeground,
      exampleBackground: exampleBackground ?? this.exampleBackground,
      exampleForeground: exampleForeground ?? this.exampleForeground,
      exerciseBackground: exerciseBackground ?? this.exerciseBackground,
      exerciseForeground: exerciseForeground ?? this.exerciseForeground,
      videoBackground: videoBackground ?? this.videoBackground,
      videoForeground: videoForeground ?? this.videoForeground,
      quizBackground: quizBackground ?? this.quizBackground,
      quizForeground: quizForeground ?? this.quizForeground,
      labBackground: labBackground ?? this.labBackground,
      labForeground: labForeground ?? this.labForeground,
      finalEvaluationBackground:
          finalEvaluationBackground ?? this.finalEvaluationBackground,
      finalEvaluationForeground:
          finalEvaluationForeground ?? this.finalEvaluationForeground,
    );
  }

  @override
  ActivityTheme lerp(ThemeExtension<ActivityTheme>? other, double t) {
    if (other is! ActivityTheme) return this;
    return ActivityTheme(
      readingBackground: Color.lerp(
        readingBackground,
        other.readingBackground,
        t,
      )!,
      readingForeground: Color.lerp(
        readingForeground,
        other.readingForeground,
        t,
      )!,
      nuggetBackground: Color.lerp(
        nuggetBackground,
        other.nuggetBackground,
        t,
      )!,
      nuggetForeground: Color.lerp(
        nuggetForeground,
        other.nuggetForeground,
        t,
      )!,
      exampleBackground: Color.lerp(
        exampleBackground,
        other.exampleBackground,
        t,
      )!,
      exampleForeground: Color.lerp(
        exampleForeground,
        other.exampleForeground,
        t,
      )!,
      exerciseBackground: Color.lerp(
        exerciseBackground,
        other.exerciseBackground,
        t,
      )!,
      exerciseForeground: Color.lerp(
        exerciseForeground,
        other.exerciseForeground,
        t,
      )!,
      videoBackground: Color.lerp(videoBackground, other.videoBackground, t)!,
      videoForeground: Color.lerp(videoForeground, other.videoForeground, t)!,
      quizBackground: Color.lerp(quizBackground, other.quizBackground, t)!,
      quizForeground: Color.lerp(quizForeground, other.quizForeground, t)!,
      labBackground: Color.lerp(labBackground, other.labBackground, t)!,
      labForeground: Color.lerp(labForeground, other.labForeground, t)!,
      finalEvaluationBackground: Color.lerp(
        finalEvaluationBackground,
        other.finalEvaluationBackground,
        t,
      )!,
      finalEvaluationForeground: Color.lerp(
        finalEvaluationForeground,
        other.finalEvaluationForeground,
        t,
      )!,
    );
  }
}
