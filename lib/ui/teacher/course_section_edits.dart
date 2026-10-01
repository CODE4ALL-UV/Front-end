/// Permite cambiar una parte del contenido sin tocar el resto.
///
/// El modelo del curso es inmutable a propósito: dos pantallas no pueden
/// pisarse los datos. Para editar, entonces, se hace una copia con lo que
/// cambia. Así el docente puede escribir tranquilo sin que el estudiante vea
/// nada hasta que pulse guardar.
///
/// El truco de `Object? x = _sinTocar`: hace falta para distinguir «no me
/// pasaron este campo» de «me lo pasaron en nulo a propósito». Sin eso no se
/// podría borrar una lectura, porque `null` significaría «déjala como está».
library;

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

const Object _sinTocar = Object();

extension CourseSectionEdits on CourseSection {
  CourseSection copyWith({
    String? title,
    Object? shortTitle = _sinTocar,
    String? summary,
    List<String>? objectives,
    Object? reading = _sinTocar,
    List<QuizQuestion>? quiz,
    List<QuizQuestion>? finalEvaluation,
    Object? capsule = _sinTocar,
    Object? example = _sinTocar,
    Object? exercise = _sinTocar,
    List<SectionVideo>? videos,
    bool? hasLaboratory,
  }) {
    return CourseSection(
      // La identidad nunca se copia con cambios: una sección editada sigue
      // siendo la misma sección.
      id: id,
      moduleNumber: moduleNumber,
      number: number,
      title: title ?? this.title,
      shortTitle: shortTitle == _sinTocar
          ? this.shortTitle
          : shortTitle as String?,
      summary: summary ?? this.summary,
      objectives: objectives ?? this.objectives,
      reading: reading == _sinTocar ? this.reading : reading as SectionReading?,
      quiz: quiz ?? this.quiz,
      finalEvaluation: finalEvaluation ?? this.finalEvaluation,
      capsule: capsule == _sinTocar
          ? this.capsule
          : capsule as KnowledgeCapsule?,
      example: example == _sinTocar ? this.example : example as CodeExample?,
      exercise: exercise == _sinTocar
          ? this.exercise
          : exercise as SectionExercise?,
      videos: videos ?? this.videos,
      hasLaboratory: hasLaboratory ?? this.hasLaboratory,
    );
  }
}

extension SectionReadingEdits on SectionReading {
  SectionReading copyWith({
    String? title,
    String? intro,
    List<ReadingPage>? pages,
  }) => SectionReading(
    title: title ?? this.title,
    intro: intro ?? this.intro,
    pages: pages ?? this.pages,
  );
}

extension ReadingPageEdits on ReadingPage {
  ReadingPage copyWith({
    String? title,
    String? summary,
    List<ReadingBlock>? blocks,
  }) => ReadingPage(
    title: title ?? this.title,
    summary: summary ?? this.summary,
    blocks: blocks ?? this.blocks,
  );
}

extension ReadingBlockEdits on ReadingBlock {
  /// Rehace el bloque conservando su tipo.
  ///
  /// Cada tipo de bloque tiene su propio constructor, así que cambiar el
  /// título de un bloque de código no puede reutilizar el de un párrafo sin
  /// perder el código por el camino.
  ReadingBlock copyWith({
    String? title,
    String? body,
    List<String>? items,
    String? code,
    Object? codeCaption = _sinTocar,
    CalloutTone? tone,
  }) {
    final newTitle = title ?? this.title;
    final newBody = body ?? this.body;
    final newItems = items ?? this.items;

    switch (kind) {
      case ReadingBlockKind.paragraph:
        return ReadingBlock.paragraph(title: newTitle, body: newBody);
      case ReadingBlockKind.bullets:
        return ReadingBlock.bullets(
          title: newTitle,
          items: newItems,
          body: newBody,
        );
      case ReadingBlockKind.steps:
        return ReadingBlock.steps(
          title: newTitle,
          items: newItems,
          body: newBody,
        );
      case ReadingBlockKind.code:
        return ReadingBlock.code(
          title: newTitle,
          code: code ?? this.code ?? '',
          body: newBody,
          codeCaption: codeCaption == _sinTocar
              ? this.codeCaption
              : codeCaption as String?,
        );
      case ReadingBlockKind.callout:
        return ReadingBlock.callout(
          title: newTitle,
          body: newBody,
          tone: tone ?? this.tone,
          items: newItems,
        );
    }
  }

  /// Convierte el bloque a otro tipo, conservando lo que tenga sentido.
  ///
  /// Pasar un párrafo a lista mantiene el título y el texto; lo que el nuevo
  /// tipo no usa se queda guardado por si se vuelve atrás en el mismo rato.
  ReadingBlock asKind(ReadingBlockKind newKind) {
    if (newKind == kind) return this;

    switch (newKind) {
      case ReadingBlockKind.paragraph:
        return ReadingBlock.paragraph(title: title, body: body);
      case ReadingBlockKind.bullets:
        return ReadingBlock.bullets(title: title, items: items, body: body);
      case ReadingBlockKind.steps:
        return ReadingBlock.steps(title: title, items: items, body: body);
      case ReadingBlockKind.code:
        return ReadingBlock.code(
          title: title,
          code: code ?? '',
          body: body,
          codeCaption: codeCaption,
        );
      case ReadingBlockKind.callout:
        return ReadingBlock.callout(
          title: title,
          body: body,
          tone: tone,
          items: items,
        );
    }
  }

  /// Un resumen de una línea para la lista del editor.
  String get editorSummary {
    switch (kind) {
      case ReadingBlockKind.paragraph:
        return body;
      case ReadingBlockKind.bullets:
      case ReadingBlockKind.steps:
        return '${items.length} ${items.length == 1 ? "punto" : "puntos"}';
      case ReadingBlockKind.code:
        return codeCaption ?? 'Fragmento de código';
      case ReadingBlockKind.callout:
        return body;
    }
  }
}

extension ReadingBlockKindLabel on ReadingBlockKind {
  String get label => switch (this) {
    ReadingBlockKind.paragraph => 'Párrafo',
    ReadingBlockKind.bullets => 'Lista de puntos',
    ReadingBlockKind.steps => 'Pasos numerados',
    ReadingBlockKind.code => 'Código',
    ReadingBlockKind.callout => 'Recuadro destacado',
  };
}

extension CalloutToneLabel on CalloutTone {
  String get label => switch (this) {
    CalloutTone.info => 'Información',
    CalloutTone.success => 'Bien hecho',
    CalloutTone.warning => 'Cuidado',
    CalloutTone.danger => 'Error frecuente',
  };
}

extension QuizQuestionEdits on QuizQuestion {
  QuizQuestion copyWith({
    String? prompt,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  }) {
    final newOptions = options ?? this.options;
    var newCorrect = correctIndex ?? this.correctIndex;

    // Si se borró la opción que era correcta, la respuesta no puede quedar
    // señalando al vacío: se recoloca en la última que exista.
    if (newOptions.isEmpty) {
      newCorrect = 0;
    } else if (newCorrect >= newOptions.length) {
      newCorrect = newOptions.length - 1;
    } else if (newCorrect < 0) {
      newCorrect = 0;
    }

    return QuizQuestion(
      prompt: prompt ?? this.prompt,
      options: newOptions,
      correctIndex: newCorrect,
      explanation: explanation ?? this.explanation,
    );
  }
}

extension KnowledgeCapsuleEdits on KnowledgeCapsule {
  KnowledgeCapsule copyWith({
    String? title,
    String? headline,
    String? intro,
    List<CapsuleTip>? tips,
    String? closing,
    Object? badCode = _sinTocar,
    Object? goodCode = _sinTocar,
    Object? badCodeCaption = _sinTocar,
    Object? goodCodeCaption = _sinTocar,
  }) => KnowledgeCapsule(
    title: title ?? this.title,
    headline: headline ?? this.headline,
    intro: intro ?? this.intro,
    tips: tips ?? this.tips,
    closing: closing ?? this.closing,
    badCode: badCode == _sinTocar ? this.badCode : badCode as String?,
    goodCode: goodCode == _sinTocar ? this.goodCode : goodCode as String?,
    badCodeCaption: badCodeCaption == _sinTocar
        ? this.badCodeCaption
        : badCodeCaption as String?,
    goodCodeCaption: goodCodeCaption == _sinTocar
        ? this.goodCodeCaption
        : goodCodeCaption as String?,
  );
}

extension CodeExampleEdits on CodeExample {
  CodeExample copyWith({
    String? title,
    String? description,
    String? code,
    String? output,
    List<ExampleStep>? steps,
    String? codeCaption,
  }) => CodeExample(
    title: title ?? this.title,
    description: description ?? this.description,
    code: code ?? this.code,
    output: output ?? this.output,
    steps: steps ?? this.steps,
    codeCaption: codeCaption ?? this.codeCaption,
  );
}

extension SectionExerciseEdits on SectionExercise {
  SectionExercise copyWith({
    String? title,
    String? instructions,
    List<ConceptPair>? pairs,
    List<QuizQuestion>? questions,
  }) => SectionExercise(
    title: title ?? this.title,
    instructions: instructions ?? this.instructions,
    pairs: pairs ?? this.pairs,
    questions: questions ?? this.questions,
  );
}

extension SectionVideoEdits on SectionVideo {
  SectionVideo copyWith({
    String? title,
    String? youtubeId,
    String? description,
    String? transcript,
    String? duration,
  }) => SectionVideo(
    title: title ?? this.title,
    youtubeId: youtubeId ?? this.youtubeId,
    description: description ?? this.description,
    transcript: transcript ?? this.transcript,
    duration: duration ?? this.duration,
  );
}

/// Saca el identificador de un video de lo que el docente pegue.
///
/// Un docente pega el enlace de YouTube, no el identificador. Aceptar las dos
/// cosas —y las formas raras de enlace— evita que tenga que aprenderse dónde
/// empieza y acaba el código.
String? extractYoutubeId(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  // Ya es un identificador suelto.
  if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(text)) return text;

  for (final pattern in [
    RegExp(r'[?&]v=([A-Za-z0-9_-]{11})'),
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{11})'),
    RegExp(r'youtube\.com/live/([A-Za-z0-9_-]{11})'),
  ]) {
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1);
  }

  return null;
}
