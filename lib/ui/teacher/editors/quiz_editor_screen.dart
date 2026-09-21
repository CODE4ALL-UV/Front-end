import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';

/// Las preguntas de un quiz o de la evaluación final.
///
/// Sirve para las dos porque son lo mismo: una lista de preguntas con opciones
/// y una correcta. Lo único que cambia es dónde se guardan.
class QuizEditorScreen extends StatefulWidget {
  const QuizEditorScreen({
    super.key,
    required this.questions,
    required this.title,
  });

  final List<QuizQuestion> questions;
  final String title;

  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen> {
  late List<QuizQuestion> _questions = [...widget.questions];

  Future<void> _editQuestion(int index) async {
    final result = await Navigator.of(context).push<QuizQuestion>(
      MaterialPageRoute(
        builder: (_) => _QuestionEditorScreen(question: _questions[index]),
      ),
    );
    if (result == null) return;

    setState(() => _questions = [..._questions]..[index] = result);
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.of(context).push<QuizQuestion>(
      MaterialPageRoute(
        builder: (_) => const _QuestionEditorScreen(
          question: QuizQuestion(
            prompt: '',
            options: ['', ''],
            correctIndex: 0,
          ),
          isNew: true,
        ),
      ),
    );
    if (result == null) return;

    setState(() => _questions = [..._questions, result]);
  }

  @override
  Widget build(BuildContext context) {
    //final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    return EditorScaffold(
      title: widget.title,
      hint:
          'Cada pregunta necesita al menos dos opciones y una marcada como '
          'correcta. La explicación se le muestra al estudiante después de '
          'responder, acierte o no.',
      onDone: () => Navigator.of(context).pop(_questions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_questions.isEmpty)
            EditorEmptyState(
              icon: Icons.quiz_outlined,
              text: 'Todavía no hay preguntas.',
              buttonLabel: 'Añadir la primera pregunta',
              onCreate: _addQuestion,
            )
          else ...[
            for (var i = 0; i < _questions.length; i++)
              TeacherListRow(
                title: _questions[i].prompt.isEmpty
                    ? 'Pregunta sin enunciado'
                    : _questions[i].prompt,
                subtitle: _describe(_questions[i]),
                position: i + 1,
                total: _questions.length,
                leading: _Number(value: i + 1),
                onTap: () => _editQuestion(i),
                onMoveUp: i == 0
                    ? null
                    : () => setState(
                        () => _questions = moveItem(_questions, i, i - 1),
                      ),
                onMoveDown: i == _questions.length - 1
                    ? null
                    : () => setState(
                        () => _questions = moveItem(_questions, i, i + 1),
                      ),
                onDelete: () async {
                  final sure = await confirmDelete(
                    context,
                    what: 'la pregunta ${i + 1}',
                  );
                  if (sure) {
                    setState(() => _questions = [..._questions]..removeAt(i));
                  }
                },
              ),
            const SizedBox(height: AppMetrics.gap),
            TeacherAddButton(label: 'Añadir pregunta', onPressed: _addQuestion),
          ],
        ],
      ),
    );
  }

  /// Avisa en la propia lista si una pregunta está a medio hacer.
  ///
  /// Es mejor verlo aquí que descubrirlo cuando el estudiante se atasque.
  String _describe(QuizQuestion question) {
    final problems = <String>[];
    if (question.prompt.trim().isEmpty) problems.add('falta el enunciado');
    if (question.options.length < 2) problems.add('faltan opciones');
    if (question.options.any((o) => o.trim().isEmpty)) {
      problems.add('hay opciones vacías');
    }

    if (problems.isNotEmpty) return '⚠ ${problems.join(", ")}';

    return '${question.options.length} opciones · '
        'correcta: ${question.correctOption}';
  }
}

class _Number extends StatelessWidget {
  const _Number({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: appTheme.dangerBorder,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: appTheme.dangerBorder,
        ),
      ),
    );
  }
}

/// Una pregunta: enunciado, opciones, cuál es la correcta y por qué.
class _QuestionEditorScreen extends StatefulWidget {
  const _QuestionEditorScreen({required this.question, this.isNew = false});

  final QuizQuestion question;
  final bool isNew;

  @override
  State<_QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<_QuestionEditorScreen> {
  late final TextEditingController _prompt = TextEditingController(
    text: widget.question.prompt,
  );
  late final TextEditingController _explanation = TextEditingController(
    text: widget.question.explanation,
  );

  late List<TextEditingController> _options = [
    for (final option in widget.question.options)
      TextEditingController(text: option),
  ];

  late int _correct = widget.question.correctIndex;

  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() => _options = [..._options, TextEditingController()]);
  }

  Future<void> _removeOption(int index) async {
    if (_options.length <= 2) {
      setState(() => _error = 'Una pregunta necesita al menos dos opciones.');
      return;
    }

    final sure = await confirmDelete(context, what: 'esta opción');
    if (!sure) return;

    setState(() {
      final removed = _options.removeAt(index);
      removed.dispose();
      _options = [..._options];

      // Si se borró la correcta, o una anterior, el índice se recoloca solo.
      if (_correct == index) {
        _correct = 0;
      } else if (_correct > index) {
        _correct--;
      }
      _error = null;
    });
  }

  void _done() {
    final prompt = _prompt.text.trim();
    final options = [for (final c in _options) c.text.trim()];

    if (prompt.isEmpty) {
      setState(() => _error = 'Escribe el enunciado de la pregunta.');
      return;
    }
    if (options.any((o) => o.isEmpty)) {
      setState(
        () => _error =
            'Hay opciones vacías. Escríbelas o quítalas antes de seguir.',
      );
      return;
    }

    Navigator.of(context).pop(
      widget.question.copyWith(
        prompt: prompt,
        options: options,
        correctIndex: _correct,
        explanation: _explanation.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return EditorScaffold(
      title: widget.isNew ? 'Nueva pregunta' : 'Editar pregunta',
      onDone: _done,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherCard(
            child: TeacherField(
              label: 'Enunciado',
              controller: _prompt,
              maxLines: 3,
              hint: '¿Qué quieres preguntar?',
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          TeacherCard(
            title: 'Opciones',
            child: RadioGroup<int>(
              groupValue: _correct,
              onChanged: (value) => setState(() => _correct = value ?? 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Marca el círculo de la respuesta correcta.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: appSemanticColors.infoText,
                    ),
                  ),
                  const SizedBox(height: AppMetrics.gap),
                  for (var i = 0; i < _options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Semantics(
                            label: _correct == i
                                ? 'Opción ${i + 1}, marcada como correcta'
                                : 'Marcar la opción ${i + 1} como correcta',
                            child: Radio<int>(
                              value: i,
                              activeColor: appSemanticColors.successBackground,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _options[i],
                              onChanged: (_) => setState(() => _error = null),
                              style: TextStyle(
                                fontSize: 14.5,
                                color: appSemanticColors.infoText,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Opción ${i + 1}',
                                isDense: true,
                                filled: true,
                                fillColor: _correct == i
                                    ? appSemanticColors.successBackground
                                    : appSemanticColors.infoBackground,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appSemanticColors.infoBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: _correct == i
                                        ? appSemanticColors.successBorder
                                        : appSemanticColors.infoBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar la opción ${i + 1}',
                            onPressed: () => _removeOption(i),
                            color: appSemanticColors.infoText,
                            constraints: const BoxConstraints(
                              minWidth: AppMetrics.minTapTarget,
                              minHeight: AppMetrics.minTapTarget,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  TeacherAddButton(
                    label: 'Añadir opción',
                    onPressed: _addOption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          TeacherCard(
            child: TeacherField(
              label: 'Explicación',
              controller: _explanation,
              maxLines: 3,
              helper:
                  'Se le muestra al estudiante después de responder. Es donde '
                  'de verdad aprende, así que conviene explicar el porqué.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppMetrics.gap),
            TeacherBanner(icon: Icons.error_outline, text: _error!),
          ],
        ],
      ),
    );
  }
}
