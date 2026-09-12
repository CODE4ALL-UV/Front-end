/// Convierte el contenido del curso a JSON y de vuelta.
///
/// Hace falta para que el docente pueda editar: lo que él guarda viaja como
/// JSON al servidor, y lo que el estudiante recibe vuelve a convertirse en el
/// mismo modelo que ya usan todas las pantallas. Al ser el mismo modelo, una
/// sección editada y una de fábrica se dibujan exactamente igual.
///
/// **Está escrito para no romperse.** Un campo que falte, que venga con otro
/// tipo o que traiga basura no revienta la aplicación: se usa el valor de
/// respaldo. Si el docente guarda algo raro, el estudiante verá una sección
/// incompleta, nunca una pantalla en blanco ni un error.
library;

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

// --- leer con red de seguridad --------------------------------------------

String _str(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

String? _strOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int _int(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _bool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

List<String> _strings(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is String) item,
      ]
    : const [];

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? [
        for (final item in value)
          if (item is Map) Map<String, dynamic>.from(item),
      ]
    : const [];

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

T _enumOf<T extends Enum>(Object? value, List<T> values, T fallback) {
  if (value is! String) return fallback;
  for (final entry in values) {
    if (entry.name == value) return entry;
  }
  return fallback;
}

// --- bloques de lectura ----------------------------------------------------

Map<String, dynamic> readingBlockToJson(ReadingBlock block) => {
  'kind': block.kind.name,
  'title': block.title,
  'body': block.body,
  'items': block.items,
  if (block.code != null) 'code': block.code,
  if (block.codeCaption != null) 'codeCaption': block.codeCaption,
  'tone': block.tone.name,
};

ReadingBlock readingBlockFromJson(Map<String, dynamic> json) {
  final kind = _enumOf(
    json['kind'],
    ReadingBlockKind.values,
    ReadingBlockKind.paragraph,
  );
  final title = _str(json['title']);
  final body = _str(json['body']);
  final items = _strings(json['items']);

  switch (kind) {
    case ReadingBlockKind.bullets:
      return ReadingBlock.bullets(title: title, items: items, body: body);
    case ReadingBlockKind.steps:
      return ReadingBlock.steps(title: title, items: items, body: body);
    case ReadingBlockKind.code:
      return ReadingBlock.code(
        title: title,
        // Un bloque de código sin código no tiene sentido, pero tampoco puede
        // tumbar la lectura entera: se queda vacío y se ve el resto.
        code: _str(json['code']),
        body: body,
        codeCaption: _strOrNull(json['codeCaption']),
      );
    case ReadingBlockKind.callout:
      return ReadingBlock.callout(
        title: title,
        body: body,
        tone: _enumOf(json['tone'], CalloutTone.values, CalloutTone.info),
        items: items,
      );
    case ReadingBlockKind.paragraph:
      return ReadingBlock.paragraph(title: title, body: body);
  }
}

// --- lectura ---------------------------------------------------------------

Map<String, dynamic> readingPageToJson(ReadingPage page) => {
  'title': page.title,
  'summary': page.summary,
  'blocks': page.blocks.map(readingBlockToJson).toList(),
};

ReadingPage readingPageFromJson(Map<String, dynamic> json) => ReadingPage(
  title: _str(json['title']),
  summary: _str(json['summary']),
  blocks: _maps(json['blocks']).map(readingBlockFromJson).toList(),
);

Map<String, dynamic> sectionReadingToJson(SectionReading reading) => {
  'title': reading.title,
  'intro': reading.intro,
  'pages': reading.pages.map(readingPageToJson).toList(),
};

SectionReading sectionReadingFromJson(Map<String, dynamic> json) =>
    SectionReading(
      title: _str(json['title']),
      intro: _str(json['intro']),
      pages: _maps(json['pages']).map(readingPageFromJson).toList(),
    );

// --- preguntas -------------------------------------------------------------

Map<String, dynamic> quizQuestionToJson(QuizQuestion question) => {
  'prompt': question.prompt,
  'options': question.options,
  'correctIndex': question.correctIndex,
  'explanation': question.explanation,
};

QuizQuestion quizQuestionFromJson(Map<String, dynamic> json) {
  final options = _strings(json['options']);

  // La respuesta correcta tiene que señalar a una opción que exista. Si el
  // índice se sale —porque se borró una opción y no se ajustó—, se usa la
  // primera en lugar de dejar que reviente al corregir el quiz.
  var correct = _int(json['correctIndex']);
  if (options.isEmpty || correct < 0 || correct >= options.length) correct = 0;

  return QuizQuestion(
    prompt: _str(json['prompt']),
    options: options,
    correctIndex: correct,
    explanation: _str(json['explanation']),
  );
}

// --- cápsula ---------------------------------------------------------------

Map<String, dynamic> capsuleTipToJson(CapsuleTip tip) => {
  'title': tip.title,
  'body': tip.body,
};

CapsuleTip capsuleTipFromJson(Map<String, dynamic> json) =>
    CapsuleTip(title: _str(json['title']), body: _str(json['body']));

Map<String, dynamic> capsuleToJson(KnowledgeCapsule capsule) => {
  'title': capsule.title,
  'headline': capsule.headline,
  'intro': capsule.intro,
  'tips': capsule.tips.map(capsuleTipToJson).toList(),
  'closing': capsule.closing,
  if (capsule.badCode != null) 'badCode': capsule.badCode,
  if (capsule.goodCode != null) 'goodCode': capsule.goodCode,
  if (capsule.badCodeCaption != null) 'badCodeCaption': capsule.badCodeCaption,
  if (capsule.goodCodeCaption != null)
    'goodCodeCaption': capsule.goodCodeCaption,
};

KnowledgeCapsule capsuleFromJson(Map<String, dynamic> json) => KnowledgeCapsule(
  title: _str(json['title']),
  headline: _str(json['headline']),
  intro: _str(json['intro']),
  tips: _maps(json['tips']).map(capsuleTipFromJson).toList(),
  closing: _str(json['closing']),
  badCode: _strOrNull(json['badCode']),
  goodCode: _strOrNull(json['goodCode']),
  badCodeCaption: _strOrNull(json['badCodeCaption']),
  goodCodeCaption: _strOrNull(json['goodCodeCaption']),
);

// --- ejemplo ---------------------------------------------------------------

Map<String, dynamic> exampleStepToJson(ExampleStep step) => {
  'code': step.code,
  'explanation': step.explanation,
};

ExampleStep exampleStepFromJson(Map<String, dynamic> json) => ExampleStep(
  code: _str(json['code']),
  explanation: _str(json['explanation']),
);

Map<String, dynamic> exampleToJson(CodeExample example) => {
  'title': example.title,
  'description': example.description,
  'code': example.code,
  'output': example.output,
  'steps': example.steps.map(exampleStepToJson).toList(),
  'codeCaption': example.codeCaption,
};

CodeExample exampleFromJson(Map<String, dynamic> json) => CodeExample(
  title: _str(json['title']),
  description: _str(json['description']),
  code: _str(json['code']),
  output: _str(json['output']),
  steps: _maps(json['steps']).map(exampleStepFromJson).toList(),
  codeCaption: _str(json['codeCaption']),
);

// --- ejercicio -------------------------------------------------------------

Map<String, dynamic> conceptPairToJson(ConceptPair pair) => {
  'concept': pair.concept,
  'definition': pair.definition,
};

ConceptPair conceptPairFromJson(Map<String, dynamic> json) => ConceptPair(
  concept: _str(json['concept']),
  definition: _str(json['definition']),
);

Map<String, dynamic> exerciseToJson(SectionExercise exercise) => {
  'title': exercise.title,
  'instructions': exercise.instructions,
  'pairs': exercise.pairs.map(conceptPairToJson).toList(),
  'questions': exercise.questions.map(quizQuestionToJson).toList(),
};

SectionExercise exerciseFromJson(Map<String, dynamic> json) => SectionExercise(
  title: _str(json['title']),
  instructions: _str(json['instructions']),
  pairs: _maps(json['pairs']).map(conceptPairFromJson).toList(),
  questions: _maps(json['questions']).map(quizQuestionFromJson).toList(),
);

// --- video -----------------------------------------------------------------

Map<String, dynamic> videoToJson(SectionVideo video) => {
  'title': video.title,
  'youtubeId': video.youtubeId,
  'description': video.description,
  'transcript': video.transcript,
  'duration': video.duration,
};

SectionVideo videoFromJson(Map<String, dynamic> json) => SectionVideo(
  title: _str(json['title']),
  youtubeId: _str(json['youtubeId']),
  description: _str(json['description']),
  transcript: _str(json['transcript']),
  duration: _str(json['duration']),
);

// --- la sección entera -----------------------------------------------------

/// Guarda la sección entera, incluidas las actividades que se quitaron.
///
/// Las que no existen se escriben como `null` **a propósito**, no se omiten.
/// Al leer, un campo ausente significa «el docente no tocó esto, deja lo de
/// fábrica» y un campo en nulo significa «el docente lo quitó». Si aquí se
/// omitieran, borrar una lectura no se quedaría borrado: volvería a aparecer
/// en cuanto el estudiante recargara.
Map<String, dynamic> sectionToJson(CourseSection section) => {
  'id': section.id,
  'moduleNumber': section.moduleNumber,
  'number': section.number,
  'title': section.title,
  'shortTitle': section.shortTitle,
  'summary': section.summary,
  'objectives': section.objectives,
  'reading': section.reading == null
      ? null
      : sectionReadingToJson(section.reading!),
  'quiz': section.quiz.map(quizQuestionToJson).toList(),
  'finalEvaluation': section.finalEvaluation.map(quizQuestionToJson).toList(),
  'capsule': section.capsule == null ? null : capsuleToJson(section.capsule!),
  'example': section.example == null ? null : exampleToJson(section.example!),
  'exercise': section.exercise == null
      ? null
      : exerciseToJson(section.exercise!),
  'videos': section.videos.map(videoToJson).toList(),
  'hasLaboratory': section.hasLaboratory,
};

/// Reconstruye una sección editada.
///
/// [fallback] es la sección de fábrica. Todo lo que el JSON no traiga se toma
/// de ella, así que un docente puede cambiar solo el título y el resto de la
/// sección sigue intacto. La identidad —el id, el módulo y el número— **nunca**
/// se toma del JSON: si se pudiera cambiar, una sección editada podría acabar
/// suplantando a otra.
CourseSection sectionFromJson(
  Map<String, dynamic> json,
  CourseSection fallback,
) {
  final reading = _map(json['reading']);
  final capsule = _map(json['capsule']);
  final example = _map(json['example']);
  final exercise = _map(json['exercise']);

  return CourseSection(
    id: fallback.id,
    moduleNumber: fallback.moduleNumber,
    number: fallback.number,
    title: _str(json['title'], fallback.title),
    shortTitle: json.containsKey('shortTitle')
        ? _strOrNull(json['shortTitle'])
        : fallback.shortTitle,
    summary: _str(json['summary'], fallback.summary),
    objectives: json.containsKey('objectives')
        ? _strings(json['objectives'])
        : fallback.objectives,
    reading: reading != null
        ? sectionReadingFromJson(reading)
        : (json.containsKey('reading') ? null : fallback.reading),
    quiz: json.containsKey('quiz')
        ? _maps(json['quiz']).map(quizQuestionFromJson).toList()
        : fallback.quiz,
    finalEvaluation: json.containsKey('finalEvaluation')
        ? _maps(json['finalEvaluation']).map(quizQuestionFromJson).toList()
        : fallback.finalEvaluation,
    capsule: capsule != null
        ? capsuleFromJson(capsule)
        : (json.containsKey('capsule') ? null : fallback.capsule),
    example: example != null
        ? exampleFromJson(example)
        : (json.containsKey('example') ? null : fallback.example),
    exercise: exercise != null
        ? exerciseFromJson(exercise)
        : (json.containsKey('exercise') ? null : fallback.exercise),
    videos: json.containsKey('videos')
        ? _maps(json['videos']).map(videoFromJson).toList()
        : fallback.videos,
    hasLaboratory: _bool(json['hasLaboratory'], fallback.hasLaboratory),
  );
}
