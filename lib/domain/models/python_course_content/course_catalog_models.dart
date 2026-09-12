/// Modelos del catálogo de contenido del curso de Python.
///
/// Todo el material educativo (lecturas, quizzes, cápsulas, ejemplos,
/// ejercicios y videos) vive como datos, no como widgets. Así una sección
/// nueva se agrega escribiendo contenido, sin duplicar pantallas, y cada
/// actividad puede describirse para lectores de pantalla y mostrarse con
/// transcripción para personas con discapacidad auditiva.
library;

import 'package:flutter/foundation.dart';

/// Tipo de bloque dentro de una página de lectura.
enum ReadingBlockKind {
  /// Texto corrido.
  paragraph,

  /// Lista de puntos.
  bullets,

  /// Fragmento de código Python.
  code,

  /// Idea destacada o advertencia.
  callout,

  /// Pasos numerados.
  steps,
}

/// Intención visual de un bloque destacado.
enum CalloutTone { info, success, warning, danger }

@immutable
class ReadingBlock {
  const ReadingBlock.paragraph({required this.title, required this.body})
    : kind = ReadingBlockKind.paragraph,
      items = const [],
      code = null,
      codeCaption = null,
      tone = CalloutTone.info;

  const ReadingBlock.bullets({
    required this.title,
    required this.items,
    this.body = '',
  }) : kind = ReadingBlockKind.bullets,
       code = null,
       codeCaption = null,
       tone = CalloutTone.info;

  const ReadingBlock.steps({
    required this.title,
    required this.items,
    this.body = '',
  }) : kind = ReadingBlockKind.steps,
       code = null,
       codeCaption = null,
       tone = CalloutTone.info;

  const ReadingBlock.code({
    required this.title,
    required String this.code,
    this.body = '',
    this.codeCaption,
  }) : kind = ReadingBlockKind.code,
       items = const [],
       tone = CalloutTone.info;

  const ReadingBlock.callout({
    required this.title,
    required this.body,
    this.tone = CalloutTone.info,
    this.items = const [],
  }) : kind = ReadingBlockKind.callout,
       code = null,
       codeCaption = null;

  final ReadingBlockKind kind;
  final String title;
  final String body;
  final List<String> items;
  final String? code;

  /// Descripción en palabras de lo que hace el código.
  ///
  /// Es lo que se lee en voz alta en lugar de deletrear símbolos, y lo que ve
  /// quien usa un lector de pantalla.
  final String? codeCaption;
  final CalloutTone tone;

  /// Versión en texto plano del bloque, para voz y para la transcripción.
  String get spokenText {
    final buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln(title);
    if (body.isNotEmpty) buffer.writeln(body);
    for (final item in items) {
      buffer.writeln(item);
    }
    if (code != null) {
      buffer.writeln(codeCaption ?? 'Ejemplo de código en Python.');
    }
    return buffer.toString().trim();
  }
}

/// Una página de lectura: lo que el estudiante ve de una sola vez.
@immutable
class ReadingPage {
  const ReadingPage({
    required this.title,
    required this.summary,
    required this.blocks,
  });

  final String title;

  /// Resumen de una frase. Se lee primero en voz alta y sirve de contexto.
  final String summary;
  final List<ReadingBlock> blocks;

  String get spokenText {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln(summary);
    for (final block in blocks) {
      buffer.writeln(block.spokenText);
    }
    return buffer.toString().trim();
  }
}

/// Lectura completa de una sección, dividida en páginas navegables.
@immutable
class SectionReading {
  const SectionReading({
    required this.title,
    required this.intro,
    required this.pages,
  });

  final String title;
  final String intro;
  final List<ReadingPage> pages;
}

/// Pregunta de opción múltiple usada en quizzes, evaluaciones y ejercicios.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;

  /// Por qué la respuesta correcta lo es. Se muestra tras responder.
  final String explanation;

  String get correctOption => options[correctIndex];
}

/// Un consejo dentro de una cápsula de conocimiento.
@immutable
class CapsuleTip {
  const CapsuleTip({required this.title, required this.body});

  final String title;
  final String body;
}

/// Cápsula de conocimiento: el "tip" que cierra cada sección.
@immutable
class KnowledgeCapsule {
  const KnowledgeCapsule({
    required this.title,
    required this.headline,
    required this.intro,
    required this.tips,
    required this.closing,
    this.badCode,
    this.goodCode,
    this.badCodeCaption,
    this.goodCodeCaption,
  });

  final String title;
  final String headline;
  final String intro;
  final List<CapsuleTip> tips;
  final String closing;

  /// Comparación "así no / así sí". Ambos deben venir juntos o ninguno.
  final String? badCode;
  final String? goodCode;
  final String? badCodeCaption;
  final String? goodCodeCaption;

  bool get hasCodeComparison => badCode != null && goodCode != null;
}

/// Una línea de código explicada dentro de un ejemplo.
@immutable
class ExampleStep {
  const ExampleStep({required this.code, required this.explanation});

  final String code;
  final String explanation;
}

/// Ejemplo de código con su salida y explicación línea por línea.
@immutable
class CodeExample {
  const CodeExample({
    required this.title,
    required this.description,
    required this.code,
    required this.output,
    this.steps = const [],
    this.codeCaption = '',
  });

  final String title;
  final String description;
  final String code;

  /// Lo que aparece en la terminal al ejecutar el código.
  final String output;
  final List<ExampleStep> steps;

  /// Resumen hablado del programa, para no deletrear símbolos en voz alta.
  final String codeCaption;
}

/// Pareja concepto-definición para el ejercicio de emparejamiento.
@immutable
class ConceptPair {
  const ConceptPair({required this.concept, required this.definition});

  final String concept;
  final String definition;
}

/// Ejercicio práctico de la sección.
///
/// Puede ser de emparejar conceptos, de opción múltiple, o ambos.
@immutable
class SectionExercise {
  const SectionExercise({
    required this.title,
    required this.instructions,
    this.pairs = const [],
    this.questions = const [],
  });

  final String title;
  final String instructions;
  final List<ConceptPair> pairs;
  final List<QuizQuestion> questions;

  bool get hasPairs => pairs.isNotEmpty;
  bool get hasQuestions => questions.isNotEmpty;
  bool get isEmpty => pairs.isEmpty && questions.isEmpty;
}

/// Video de apoyo de la sección.
@immutable
class SectionVideo {
  const SectionVideo({
    required this.title,
    required this.youtubeId,
    required this.description,
    this.transcript = '',
    this.duration = '',
  });

  final String title;

  /// Identificador de 11 caracteres del video en YouTube.
  final String youtubeId;

  final String description;

  /// Duración en formato m:ss, para que se sepa de antemano.
  final String duration;

  /// URL completa, derivada del identificador.
  String get url => 'https://www.youtube.com/watch?v=$youtubeId';

  /// Resumen escrito de lo que explica el video.
  ///
  /// Imprescindible para estudiantes con discapacidad auditiva: el contenido
  /// del video tiene que estar disponible también en texto.
  final String transcript;
}

/// Una sección (tema) del curso, con todas sus actividades.
@immutable
class CourseSection {
  const CourseSection({
    required this.id,
    required this.moduleNumber,
    required this.number,
    required this.title,
    required this.summary,
    required this.objectives,
    this.shortTitle,
    this.reading,
    this.quiz = const [],
    this.finalEvaluation = const [],
    this.capsule,
    this.example,
    this.exercise,
    this.videos = const [],
    this.hasLaboratory = true,
  });

  final String id;
  final int moduleNumber;
  final int number;
  final String title;

  /// Versión con saltos de línea para la tarjeta de la portada del módulo.
  ///
  /// Sin esto, un título largo como "Bucles y estructuras iterativas" se
  /// encoge hasta volverse ilegible dentro de la tarjeta.
  final String? shortTitle;

  /// Descripción corta que se muestra en la tarjeta del capítulo.
  final String summary;
  final List<String> objectives;

  final SectionReading? reading;
  final List<QuizQuestion> quiz;
  final List<QuizQuestion> finalEvaluation;
  final KnowledgeCapsule? capsule;
  final CodeExample? example;
  final SectionExercise? exercise;

  /// Videos de la sección, en el orden en que conviene verlos.
  final List<SectionVideo> videos;

  final bool hasLaboratory;

  /// Etiqueta usada en cabeceras: "Capítulo 2: El entorno".
  String get displayTitle => 'Capítulo $number: $title';

  /// Título tal y como se muestra en la tarjeta de la portada del módulo.
  ///
  /// Siempre sale del catálogo, nunca del backend: así el título que ve el
  /// estudiante y el contenido que abre no pueden desincronizarse.
  String get boxTitle => shortTitle ?? title;

  /// `true` cuando la sección todavía no tiene material cargado.
  bool get isPlaceholder => reading == null && quiz.isEmpty && capsule == null;

  int get readingPageCount => reading?.pages.length ?? 0;

  int get activityCount {
    var count = 0;
    if (reading != null) count++;
    if (capsule != null) count++;
    if (example != null) count++;
    if (exercise != null && !exercise!.isEmpty) count++;
    if (quiz.isNotEmpty) count++;
    if (finalEvaluation.isNotEmpty) count++;
    if (videos.isNotEmpty) count++;
    if (hasLaboratory) count++;
    return count;
  }
}

/// Un módulo del curso, con sus secciones.
@immutable
class CourseModule {
  const CourseModule({
    required this.number,
    required this.title,
    required this.sections,
  });

  final int number;
  final String title;
  final List<CourseSection> sections;

  /// Etiqueta de la franja superior: "Módulo 1. Preparación".
  String get label => 'Módulo $number. $title';

  CourseSection? sectionByNumber(int number) {
    for (final section in sections) {
      if (section.number == number) return section;
    }
    return null;
  }
}
