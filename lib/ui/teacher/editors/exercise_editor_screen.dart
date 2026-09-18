import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';
import 'quiz_editor_screen.dart';

/// El ejercicio de la sección: emparejar conceptos y responder preguntas.
class ExerciseEditorScreen extends StatefulWidget {
  const ExerciseEditorScreen({super.key, required this.exercise});

  final SectionExercise? exercise;

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  SectionExercise? _exercise;

  late final TextEditingController _title;
  late final TextEditingController _instructions;

  late List<_PairFields> _pairs;
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _exercise = exercise;

    _title = TextEditingController(text: exercise?.title ?? '');
    _instructions = TextEditingController(text: exercise?.instructions ?? '');
    _questions = [...?exercise?.questions];
    _pairs = [
      for (final pair in exercise?.pairs ?? const <ConceptPair>[])
        _PairFields(pair.concept, pair.definition),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _instructions.dispose();
    for (final pair in _pairs) {
      pair.dispose();
    }
    super.dispose();
  }

  SectionExercise? get _result {
    final exercise = _exercise;
    if (exercise == null) return null;

    return exercise.copyWith(
      title: _title.text.trim(),
      instructions: _instructions.text.trim(),
      pairs: [
        for (final pair in _pairs)
          if (pair.hasContent) pair.toPair(),
      ],
      questions: _questions,
    );
  }

  Future<void> _editQuestions() async {
    final result = await Navigator.of(context).push<List<QuizQuestion>>(
      MaterialPageRoute(
        builder: (_) => QuizEditorScreen(
          questions: _questions,
          title: 'Preguntas del ejercicio',
        ),
      ),
    );
    if (result != null) setState(() => _questions = result);
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    return EditorScaffold(
      title: 'Ejercicio',
      onDelete: _exercise == null
          ? null
          : () async {
              final sure = await confirmDelete(context, what: 'el ejercicio');
              if (sure && context.mounted) setState(() => _exercise = null);
            },
      onDone: () => Navigator.of(context).pop(_result),
      child: _exercise == null
          ? EditorEmptyState(
              icon: Icons.edit_note,
              text: 'Esta sección no tiene ejercicio.',
              buttonLabel: 'Crear el ejercicio',
              onCreate: () => setState(() {
                _exercise = const SectionExercise(
                  title: 'Ejercicio',
                  instructions: '',
                );
                _title.text = 'Ejercicio';
                _pairs = [_PairFields('', '')];
              }),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherCard(
                  child: Column(
                    children: [
                      TeacherField(label: 'Título', controller: _title),
                      const SizedBox(height: AppMetrics.gap),
                      TeacherField(
                        label: 'Instrucciones',
                        controller: _instructions,
                        maxLines: 3,
                        helper: 'Qué tiene que hacer el estudiante.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppMetrics.sectionGap),
                Text(
                  'Emparejar conceptos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: appTheme.textTitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'El estudiante une cada concepto con su definición. Déjalo '
                  'vacío si este ejercicio no lo necesita.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: appTheme.textSubtitle,
                  ),
                ),
                const SizedBox(height: AppMetrics.gap),
                for (var i = 0; i < _pairs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TeacherCard(
                      title: 'Pareja ${i + 1}',
                      action: IconButton(
                        tooltip: 'Quitar la pareja ${i + 1}',
                        onPressed: () async {
                          final sure = await confirmDelete(
                            context,
                            what: 'la pareja ${i + 1}',
                          );
                          if (sure) {
                            setState(() {
                              _pairs.removeAt(i).dispose();
                              _pairs = [..._pairs];
                            });
                          }
                        },
                        color: appTheme.textSubtitle,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                      child: Column(
                        children: [
                          TeacherField(
                            label: 'Concepto',
                            controller: _pairs[i].concept,
                          ),
                          const SizedBox(height: 10),
                          TeacherField(
                            label: 'Definición',
                            controller: _pairs[i].definition,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                TeacherAddButton(
                  label: 'Añadir pareja',
                  onPressed: () =>
                      setState(() => _pairs = [..._pairs, _PairFields('', '')]),
                ),
                const SizedBox(height: AppMetrics.sectionGap),
                TeacherCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.quiz_outlined,
                      color: appTheme.successBorder,
                    ),
                    title: Text(
                      'Preguntas del ejercicio',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: appTheme.textTitle,
                      ),
                    ),
                    subtitle: Text(
                      _questions.isEmpty
                          ? 'Sin preguntas'
                          : '${_questions.length} '
                                '${_questions.length == 1 ? "pregunta" : "preguntas"}',
                      style: TextStyle(color: appTheme.textSubtitle),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: appTheme.textSubtitle,
                    ),
                    onTap: _editQuestions,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PairFields {
  _PairFields(String concept, String definition)
    : concept = TextEditingController(text: concept),
      definition = TextEditingController(text: definition);

  final TextEditingController concept;
  final TextEditingController definition;

  bool get hasContent =>
      concept.text.trim().isNotEmpty || definition.text.trim().isNotEmpty;

  ConceptPair toPair() => ConceptPair(
    concept: concept.text.trim(),
    definition: definition.text.trim(),
  );

  void dispose() {
    concept.dispose();
    definition.dispose();
  }
}
