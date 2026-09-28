import 'package:flutter/material.dart';

// info: azul
// success: verde
// warning: amarillo
// danger: rojo
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
  final Color readingBorder;
  final Color readingText;
  final Color nuggetBackground;
  final Color nuggetBorder;
  final Color nuggetText;
  final Color exampleBackground;
  final Color exampleBorder;
  final Color exampleText;
  final Color exerciseBackground;
  final Color exerciseBorder;
  final Color exerciseText;
  final Color videoBackground;
  final Color videoBorder;
  final Color videoText;
  final Color quizBackground;
  final Color quizBorder;
  final Color quizText;
  final Color labBackground;
  final Color labBorder;
  final Color labText;
  final Color finalEvaluationBackground;
  final Color finalEvaluationBorder;
  final Color finalEvaluationText;

  const ActivityTheme({
    required this.readingBackground,
    required this.readingBorder,
    required this.readingText,
    required this.nuggetBackground,
    required this.nuggetBorder,
    required this.nuggetText,
    required this.exampleBackground,
    required this.exampleBorder,
    required this.exampleText,
    required this.exerciseBackground,
    required this.exerciseBorder,
    required this.exerciseText,
    required this.videoBackground,
    required this.videoBorder,
    required this.videoText,
    required this.quizBackground,
    required this.quizBorder,
    required this.quizText,
    required this.labBackground,
    required this.labBorder,
    required this.labText,
    required this.finalEvaluationBackground,
    required this.finalEvaluationBorder,
    required this.finalEvaluationText,
  });

  ({Color background, Color border, Color text}) tone(ActivityThemeTone tone) =>
      switch (tone) {
        ActivityThemeTone.reading => (
          background: readingBackground,
          border: readingBorder,
          text: readingText,
        ),
        ActivityThemeTone.nugget => (
          background: nuggetBackground,
          border: nuggetBorder,
          text: nuggetText,
        ),
        ActivityThemeTone.example => (
          background: exampleBackground,
          border: exampleBorder,
          text: exampleText,
        ),
        ActivityThemeTone.exercise => (
          background: exerciseBackground,
          border: exerciseBorder,
          text: exerciseText,
        ),
        ActivityThemeTone.video => (
          background: videoBackground,
          border: videoBorder,
          text: videoText,
        ),
        ActivityThemeTone.quiz => (
          background: quizBackground,
          border: quizBorder,
          text: quizText,
        ),
        ActivityThemeTone.lab => (
          background: labBackground,
          border: labBorder,
          text: labText,
        ),
        ActivityThemeTone.finalEvaluation => (
          background: finalEvaluationBackground,
          border: finalEvaluationBorder,
          text: finalEvaluationText,
        ),
      };

  @override
  ActivityTheme copyWith({
    Color? readingBackground,
    Color? readingBorder,
    Color? readingText,
    Color? nuggetBackground,
    Color? nuggetBorder,
    Color? nuggetText,
    Color? exampleBackground,
    Color? exampleBorder,
    Color? exampleText,
    Color? exerciseBackground,
    Color? exerciseBorder,
    Color? exerciseText,
    Color? videoBackground,
    Color? videoBorder,
    Color? videoText,
    Color? quizBackground,
    Color? quizBorder,
    Color? quizText,
    Color? labBackground,
    Color? labBorder,
    Color? labText,
    Color? finalEvaluationBackground,
    Color? finalEvaluationBorder,
    Color? finalEvaluationText,
  }) {
    return ActivityTheme(
      readingBackground: readingBackground ?? this.readingBackground,
      readingBorder: readingBorder ?? this.readingBorder,
      readingText: readingText ?? this.readingText,
      nuggetBackground: nuggetBackground ?? this.nuggetBackground,
      nuggetBorder: nuggetBorder ?? this.nuggetBorder,
      nuggetText: nuggetText ?? this.nuggetText,
      exampleBackground: exampleBackground ?? this.exampleBackground,
      exampleBorder: exampleBorder ?? this.exampleBorder,
      exampleText: exampleText ?? this.exampleText,
      exerciseBackground: exerciseBackground ?? this.exerciseBackground,
      exerciseBorder: exerciseBorder ?? this.exerciseBorder,
      exerciseText: exerciseText ?? this.exerciseText,
      videoBackground: videoBackground ?? this.videoBackground,
      videoBorder: videoBorder ?? this.videoBorder,
      videoText: videoText ?? this.videoText,
      quizBackground: quizBackground ?? this.quizBackground,
      quizBorder: quizBorder ?? this.quizBorder,
      quizText: quizText ?? this.quizText,
      labBackground: labBackground ?? this.labBackground,
      labBorder: labBorder ?? this.labBorder,
      labText: labText ?? this.labText,
      finalEvaluationBackground:
          finalEvaluationBackground ?? this.finalEvaluationBackground,
      finalEvaluationBorder:
          finalEvaluationBorder ?? this.finalEvaluationBorder,
      finalEvaluationText: finalEvaluationText ?? this.finalEvaluationText,
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
      readingBorder: Color.lerp(readingBorder, other.readingBorder, t)!,
      readingText: Color.lerp(readingText, other.readingText, t)!,
      nuggetBackground: Color.lerp(
        nuggetBackground,
        other.nuggetBackground,
        t,
      )!,
      nuggetBorder: Color.lerp(nuggetBorder, other.nuggetBorder, t)!,
      nuggetText: Color.lerp(nuggetText, other.nuggetText, t)!,
      exampleBackground: Color.lerp(
        exampleBackground,
        other.exampleBackground,
        t,
      )!,
      exampleBorder: Color.lerp(exampleBorder, other.exampleBorder, t)!,
      exampleText: Color.lerp(exampleText, other.exampleText, t)!,
      exerciseBackground: Color.lerp(
        exerciseBackground,
        other.exerciseBackground,
        t,
      )!,
      exerciseBorder: Color.lerp(exerciseBorder, other.exerciseBorder, t)!,
      exerciseText: Color.lerp(exerciseText, other.exerciseText, t)!,
      videoBackground: Color.lerp(videoBackground, other.videoBackground, t)!,
      videoBorder: Color.lerp(videoBorder, other.videoBorder, t)!,
      videoText: Color.lerp(videoText, other.videoText, t)!,
      quizBackground: Color.lerp(quizBackground, other.quizBackground, t)!,
      quizBorder: Color.lerp(quizBorder, other.quizBorder, t)!,
      quizText: Color.lerp(quizText, other.quizText, t)!,
      labBackground: Color.lerp(labBackground, other.labBackground, t)!,
      labBorder: Color.lerp(labBorder, other.labBorder, t)!,
      labText: Color.lerp(labText, other.labText, t)!,
      finalEvaluationBackground: Color.lerp(
        finalEvaluationBackground,
        other.finalEvaluationBackground,
        t,
      )!,
      finalEvaluationBorder: Color.lerp(
        finalEvaluationBorder,
        other.finalEvaluationBorder,
        t,
      )!,
      finalEvaluationText: Color.lerp(
        finalEvaluationText,
        other.finalEvaluationText,
        t,
      )!,
    );
  }
}
