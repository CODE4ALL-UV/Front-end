import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

import 'section_activity_scaffold.dart';
import 'section_theme.dart';
import 'section_widgets.dart';

/// Ejemplo de código con su salida y su explicación línea por línea.
class SectionExampleScreen extends StatelessWidget {
  const SectionExampleScreen({
    super.key,
    required this.module,
    required this.section,
  });

  final CourseModule module;
  final CourseSection section;

  CodeExample get _example => section.example!;

  String get _spokenText {
    final buffer = StringBuffer()
      ..writeln(_example.title)
      ..writeln(_example.description);

    if (_example.codeCaption.isNotEmpty) {
      buffer.writeln('Qué hace el programa: ${_example.codeCaption}');
    }

    buffer.writeln('Esto es lo que se ve en la terminal al ejecutarlo:');
    buffer.writeln(_example.output);

    if (_example.steps.isNotEmpty) {
      buffer.writeln('Explicación línea por línea:');
      for (var i = 0; i < _example.steps.length; i++) {
        buffer.writeln('Paso ${i + 1}. ${_example.steps[i].explanation}');
      }
    }

    return buffer.toString();
  }

  Future<void> _finish(BuildContext context) async {
    await CourseProgressStore.instance.markCompleted(
      section.id,
      CourseActivityKind.ejemplo,
    );

    if (!context.mounted) return;

    announceForAccessibility(context, 'Ejemplo completado.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionActivityScaffold(
      moduleLabel: module.label,
      sectionTitle: section.displayTitle,
      activityLabel: 'Ejemplo',
      activityIcon: Icons.terminal_outlined,
      spokenText: _spokenText,
      bottomBar: SectionPrimaryButton(
        label: 'Marcar ejemplo como revisado',
        icon: Icons.check_circle_outline,
        tone: SectionTone.success,
        semanticHint: 'Marca el ejemplo como completado y vuelve a la ruta',
        onPressed: () => _finish(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            background: palette.accentSoft,
            borderColor: palette.accent.withValues(alpha: 0.4),
            child: SectionHeading(
              title: _example.title,
              subtitle: _example.description,
              icon: Icons.code,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: SectionMetrics.sectionGap),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  title: 'El programa',
                  icon: Icons.data_object,
                ),
                const SizedBox(height: 14),
                SectionCodeBlock(
                  code: _example.code,
                  caption: _example.codeCaption.isEmpty
                      ? null
                      : _example.codeCaption,
                ),
              ],
            ),
          ),
          const SizedBox(height: SectionMetrics.sectionGap),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  title: 'Resultado en la terminal',
                  subtitle: 'Esto es lo que verás al ejecutar el programa.',
                  icon: Icons.monitor_outlined,
                ),
                const SizedBox(height: 14),
                _OutputBlock(output: _example.output),
              ],
            ),
          ),
          if (_example.steps.isNotEmpty) ...[
            const SizedBox(height: SectionMetrics.sectionGap),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: 'Explicación línea por línea',
                    icon: Icons.format_list_numbered,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _example.steps.length; i++)
                    _StepRow(index: i + 1, step: _example.steps[i]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Salida de la terminal. Se lee tal cual, porque el resultado en texto es
/// justamente lo que necesita entender el estudiante.
class _OutputBlock extends StatefulWidget {
  const _OutputBlock({required this.output});

  final String output;

  @override
  State<_OutputBlock> createState() => _OutputBlockState();
}

class _OutputBlockState extends State<_OutputBlock> {
  /// Igual que en los bloques de código: el scroll horizontal necesita su
  /// propio controlador para que la barra tenga una posición a la que
  /// engancharse.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: palette.success, width: 4)),
      ),
      child: Scrollbar(
        controller: _controller,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(14),
          child: SelectableText(
            widget.output,
            style: TextStyle(
              fontFamily: 'monospace',
              fontFamilyFallback: const [
                'Roboto Mono',
                'Consolas',
                'Courier New',
              ],
              fontSize: 14,
              height: 1.55,
              color: palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.step});

  final int index;
  final ExampleStep step;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Línea de código',
                  child: ExcludeSemantics(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.codeBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.codeBorder),
                      ),
                      child: SelectableText(
                        step.code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontFamilyFallback: const [
                            'Roboto Mono',
                            'Consolas',
                            'Courier New',
                          ],
                          fontSize: 13.5,
                          height: 1.5,
                          color: palette.codeText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.explanation,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
