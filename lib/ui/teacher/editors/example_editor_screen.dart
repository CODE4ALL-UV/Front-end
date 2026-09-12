import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';

/// El ejemplo comentado: código con su explicación paso a paso.
class ExampleEditorScreen extends StatefulWidget {
  const ExampleEditorScreen({super.key, required this.example});

  final CodeExample? example;

  @override
  State<ExampleEditorScreen> createState() => _ExampleEditorScreenState();
}

class _ExampleEditorScreenState extends State<ExampleEditorScreen> {
  CodeExample? _example;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _code;
  late final TextEditingController _caption;
  late final TextEditingController _output;

  late List<_StepFields> _steps;

  @override
  void initState() {
    super.initState();
    final example = widget.example;
    _example = example;

    _title = TextEditingController(text: example?.title ?? '');
    _description = TextEditingController(text: example?.description ?? '');
    _code = TextEditingController(text: example?.code ?? '');
    _caption = TextEditingController(text: example?.codeCaption ?? '');
    _output = TextEditingController(text: example?.output ?? '');

    _steps = [
      for (final step in example?.steps ?? const <ExampleStep>[])
        _StepFields(step.code, step.explanation),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _code.dispose();
    _caption.dispose();
    _output.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  CodeExample? get _result {
    final example = _example;
    if (example == null) return null;

    return example.copyWith(
      title: _title.text.trim(),
      description: _description.text.trim(),
      code: _code.text,
      codeCaption: _caption.text.trim(),
      output: _output.text,
      steps: [
        for (final step in _steps)
          if (step.hasContent) step.toStep(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return EditorScaffold(
      title: 'Ejemplo comentado',
      onDelete: _example == null
          ? null
          : () async {
              final sure = await confirmDelete(context, what: 'el ejemplo');
              if (sure && context.mounted) setState(() => _example = null);
            },
      onDone: () => Navigator.of(context).pop(_result),
      child: _example == null
          ? EditorEmptyState(
              palette: palette,
              icon: Icons.code,
              text: 'Esta sección no tiene ejemplo comentado.',
              buttonLabel: 'Crear el ejemplo',
              onCreate: () => setState(() {
                _example = const CodeExample(
                  title: 'Ejemplo',
                  description: '',
                  code: '',
                  output: '',
                );
                _title.text = 'Ejemplo';
              }),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherCard(
                  palette: palette,
                  child: Column(
                    children: [
                      TeacherField(
                        palette: palette,
                        label: 'Título',
                        controller: _title,
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Descripción',
                        controller: _description,
                        maxLines: 3,
                        helper: 'Qué resuelve este ejemplo.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SectionMetrics.gap),
                TeacherCard(
                  palette: palette,
                  title: 'El código',
                  child: Column(
                    children: [
                      TeacherField(
                        palette: palette,
                        label: 'Código completo',
                        controller: _code,
                        maxLines: 12,
                        monospace: true,
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Qué hace, en palabras',
                        controller: _caption,
                        maxLines: 2,
                        helper:
                            'Es lo que se lee en voz alta en lugar de '
                            'deletrear el código símbolo a símbolo.',
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Lo que aparece al ejecutarlo',
                        controller: _output,
                        maxLines: 5,
                        monospace: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SectionMetrics.sectionGap),
                Text(
                  'Explicación paso a paso',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cada paso toma un trozo del código y explica qué hace. Es '
                  'lo que convierte un ejemplo en una lección.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: SectionMetrics.gap),
                for (var i = 0; i < _steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TeacherCard(
                      palette: palette,
                      title: 'Paso ${i + 1}',
                      action: IconButton(
                        tooltip: 'Quitar el paso ${i + 1}',
                        onPressed: () async {
                          final sure = await confirmDelete(
                            context,
                            what: 'el paso ${i + 1}',
                          );
                          if (sure) {
                            setState(() {
                              _steps.removeAt(i).dispose();
                              _steps = [..._steps];
                            });
                          }
                        },
                        color: palette.textSecondary,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                      child: Column(
                        children: [
                          TeacherField(
                            palette: palette,
                            label: 'Trozo de código',
                            controller: _steps[i].code,
                            maxLines: 4,
                            monospace: true,
                          ),
                          const SizedBox(height: 10),
                          TeacherField(
                            palette: palette,
                            label: 'Qué hace',
                            controller: _steps[i].explanation,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                TeacherAddButton(
                  palette: palette,
                  label: 'Añadir paso',
                  onPressed: () =>
                      setState(() => _steps = [..._steps, _StepFields('', '')]),
                ),
              ],
            ),
    );
  }
}

class _StepFields {
  _StepFields(String code, String explanation)
    : code = TextEditingController(text: code),
      explanation = TextEditingController(text: explanation);

  final TextEditingController code;
  final TextEditingController explanation;

  bool get hasContent =>
      code.text.trim().isNotEmpty || explanation.text.trim().isNotEmpty;

  ExampleStep toStep() =>
      ExampleStep(code: code.text.trim(), explanation: explanation.text.trim());

  void dispose() {
    code.dispose();
    explanation.dispose();
  }
}
