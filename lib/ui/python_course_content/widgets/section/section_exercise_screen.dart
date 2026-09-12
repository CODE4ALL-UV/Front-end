import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

import 'section_quiz_screen.dart';

/// Ejercicio práctico de una sección.
///
/// Los ejercicios de emparejar concepto y definición se presentan como
/// preguntas de opción múltiple en lugar de arrastrar y soltar: arrastrar es
/// prácticamente imposible con un lector de pantalla o con motricidad
/// reducida, mientras que elegir una opción funciona con dedo, teclado,
/// conmutador o voz.
class SectionExerciseScreen extends StatelessWidget {
  const SectionExerciseScreen({
    super.key,
    required this.module,
    required this.section,
  });

  final CourseModule module;
  final CourseSection section;

  @override
  Widget build(BuildContext context) {
    final exercise = section.exercise!;

    return SectionQuizScreen(
      module: module,
      section: section,
      questions: buildExerciseQuestions(exercise),
      activityKind: CourseActivityKind.ejercicio,
      activityLabel: 'Ejercicio',
      activityIcon: Icons.fitness_center_outlined,
      introTitle: exercise.title,
      introBody: exercise.instructions,
    );
  }
}

/// Convierte un ejercicio en la lista de preguntas que se mostrarán.
///
/// Es visible para poder probarla sin levantar la interfaz.
@visibleForTesting
List<QuizQuestion> buildExerciseQuestions(SectionExercise exercise) {
  final questions = <QuizQuestion>[];

  final definitions = [for (final pair in exercise.pairs) pair.definition];

  for (var i = 0; i < exercise.pairs.length; i++) {
    final pair = exercise.pairs[i];
    final options = _optionsFor(
      correct: pair.definition,
      pool: definitions,
      correctIndexInPool: i,
    );

    questions.add(
      QuizQuestion(
        prompt: '¿Qué describe mejor "${pair.concept}"?',
        options: options,
        correctIndex: options.indexOf(pair.definition),
        explanation: '${pair.concept}: ${pair.definition}',
      ),
    );
  }

  questions.addAll(exercise.questions);
  return questions;
}

/// Arma las opciones de una pregunta de emparejamiento.
///
/// El orden es determinista —depende de la posición del concepto— para que la
/// respuesta correcta no caiga siempre en el mismo lugar, pero el ejercicio se
/// comporte igual cada vez que se abre.
List<String> _optionsFor({
  required String correct,
  required List<String> pool,
  required int correctIndexInPool,
}) {
  const maxOptions = 4;

  final distractors = <String>[];
  for (var offset = 1; offset < pool.length; offset++) {
    if (distractors.length >= maxOptions - 1) break;
    final candidate = pool[(correctIndexInPool + offset) % pool.length];
    if (candidate != correct && !distractors.contains(candidate)) {
      distractors.add(candidate);
    }
  }

  final options = List<String>.from(distractors);
  final insertAt = distractors.isEmpty
      ? 0
      : correctIndexInPool % (distractors.length + 1);
  options.insert(insertAt, correct);

  return options;
}
