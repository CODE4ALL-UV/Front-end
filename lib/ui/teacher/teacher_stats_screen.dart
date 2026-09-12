import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'teacher_report.dart';
import 'teacher_widgets.dart';

/// Qué se entiende del curso y qué no.
///
/// Todo lo que sale aquí viene de lo que los estudiantes han respondido de
/// verdad. Si nadie ha respondido nada, la pantalla lo dice con esas palabras
/// en vez de enseñar ceros, porque un cero se lee como «lo hacen fatal» y no
/// como «todavía no hay datos».
///
/// Los gráficos son barras dibujadas con widgets normales, no una imagen: así
/// cada barra lleva su número al lado y su etiqueta para el lector de
/// pantalla. Un gráfico que solo se entiende mirándolo deja fuera a parte del
/// profesorado.
class TeacherStatsScreen extends StatefulWidget {
  const TeacherStatsScreen({super.key});

  @override
  State<TeacherStatsScreen> createState() => _TeacherStatsScreenState();
}

class _TeacherStatsScreenState extends State<TeacherStatsScreen> {
  final CourseAnalyticsStore _stats = CourseAnalyticsStore.instance;

  @override
  void initState() {
    super.initState();
    _stats.addListener(_onChanged);
    if (!_stats.isLoaded) _stats.refresh();
  }

  @override
  void dispose() {
    _stats.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    if (_stats.isLoading && !_stats.isLoaded) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    return RefreshIndicator(
      onRefresh: _stats.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: SectionMetrics.pagePadding(constraints.maxWidth),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SectionMetrics.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _body(palette),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _body(SectionPalette palette) {
    if (_stats.problem != null) {
      return [
        TeacherBanner(
          palette: palette,
          icon: Icons.cloud_off,
          text: _stats.problem!,
          tone: palette.danger,
        ),
        const SizedBox(height: SectionMetrics.gap),
        Center(
          child: FilledButton.icon(
            onPressed: _stats.refresh,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              minimumSize: const Size(0, SectionMetrics.minTapTarget),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Volver a intentarlo'),
          ),
        ),
      ];
    }

    if (_stats.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(SectionMetrics.sectionGap),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          ),
          child: Column(
            children: [
              Icon(Icons.insights, size: 44, color: palette.textSecondary),
              const SizedBox(height: SectionMetrics.gap),
              Text(
                'Todavía no hay actividad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estas cifras salen de lo que hacen tus estudiantes: las '
                'lecturas que terminan, los videos que ven y los quiz que '
                'responden. En cuanto alguno empiece, aparecerá aquí hasta '
                'dónde llegan y qué temas cuestan más.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final hardSections = _stats.hardestSections();
    final hardQuestions = _stats.hardestQuestions();

    return [
      _summaryRow(palette),
      const SizedBox(height: SectionMetrics.sectionGap),

      _sectionTitle(palette, 'Aciertos por sección', Icons.bar_chart),
      const SizedBox(height: 6),
      _note(
        palette,
        'Ordenadas de la que peor va a la que mejor. Solo salen las que ya '
        'tienen al menos tres respuestas: con menos, un porcentaje bajo dice '
        'que casi nadie lo ha hecho, no que sea difícil.',
      ),
      const SizedBox(height: SectionMetrics.gap),
      if (hardSections.isEmpty)
        _note(
          palette,
          'Ninguna sección tiene todavía suficientes respuestas para comparar.',
        )
      else
        for (final section in hardSections)
          _SectionBar(palette: palette, stats: section),

      const SizedBox(height: SectionMetrics.sectionGap),
      _sectionTitle(palette, 'Hasta dónde llegan', Icons.task_alt),
      const SizedBox(height: 6),
      _note(
        palette,
        'Cuántos estudiantes terminan cada actividad. Donde la cifra cae de '
        'golpe es donde la gente abandona la sección.',
      ),
      const SizedBox(height: SectionMetrics.gap),
      if (_stats.totalCompletions == 0)
        _note(palette, 'Todavía nadie ha terminado ninguna actividad.')
      else
        for (final section in _sectionsWithCompletions())
          _CompletionRow(palette: palette, title: section.$1, done: section.$2),

      const SizedBox(height: SectionMetrics.sectionGap),
      _sectionTitle(
        palette,
        'Preguntas que más tiempo cuestan',
        Icons.timer_outlined,
      ),
      const SizedBox(height: 6),
      _note(
        palette,
        'Una pregunta que casi todos aciertan pero que lleva un minuto suele '
        'estar mal redactada, no ser difícil. Es una señal distinta de '
        'fallarla.',
      ),
      const SizedBox(height: SectionMetrics.gap),
      if (_stats.slowestQuestions().isEmpty)
        _note(palette, 'Todavía no hay tiempos medidos.')
      else
        for (final question in _stats.slowestQuestions())
          _QuestionRow(palette: palette, stats: question, showTime: true),

      const SizedBox(height: SectionMetrics.sectionGap),
      _sectionTitle(palette, 'Preguntas que más se fallan', Icons.help_outline),
      const SizedBox(height: 6),
      _note(
        palette,
        'Si una pregunta la falla casi todo el mundo, suele ser que el '
        'enunciado confunde o que el tema no quedó explicado. Puedes editarla '
        'desde la pestaña del temario.',
      ),
      const SizedBox(height: SectionMetrics.gap),
      if (hardQuestions.isEmpty)
        _note(palette, 'Todavía no hay preguntas con respuestas suficientes.')
      else
        for (final question in hardQuestions)
          _QuestionRow(palette: palette, stats: question),

      const SizedBox(height: SectionMetrics.sectionGap),
      Center(
        child: OutlinedButton.icon(
          onPressed: () => showReportSheet(context, _stats),
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.accent,
            side: BorderSide(color: palette.border),
            minimumSize: const Size(0, SectionMetrics.minTapTarget),
          ),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Generar informe'),
        ),
      ),
      const SizedBox(height: 30),
    ];
  }

  Widget _summaryRow(SectionPalette palette) {
    final accuracy = (_stats.overallAccuracy * 100).round();

    return Wrap(
      spacing: SectionMetrics.gap,
      runSpacing: SectionMetrics.gap,
      children: [
        _Metric(
          palette: palette,
          label: 'Actividades hechas',
          value: '${_stats.totalCompletions}',
          icon: Icons.task_alt,
        ),
        _Metric(
          palette: palette,
          label: 'Respuestas',
          value: '${_stats.totalAnswers}',
          icon: Icons.checklist,
        ),
        _Metric(
          palette: palette,
          label: 'Aciertos',
          value: '$accuracy %',
          icon: Icons.check_circle_outline,
          tone: accuracy >= 60 ? palette.success : palette.warning,
        ),
        _Metric(
          palette: palette,
          label: 'Han empezado',
          value: '${_stats.activeStudents} de ${_stats.students.length}',
          icon: Icons.groups_outlined,
        ),
      ],
    );
  }

  Widget _sectionTitle(SectionPalette palette, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: palette.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Las secciones con actividades terminadas, con su reparto.
  ///
  /// Se ordenan por el temario y no por cantidad: el docente quiere ver el
  /// recorrido del curso, que es donde se nota el abandono.
  List<(String, Map<String, int>)> _sectionsWithCompletions() {
    final ids = <String>{for (final item in _stats.completions) item.sectionId};

    final out = <(String, Map<String, int>)>[];
    for (final id in ids) {
      out.add((
        PythonCourseCatalog.sectionById(id)?.title ?? id,
        _stats.completionsOf(id),
      ));
    }

    out.sort((a, b) => a.$1.compareTo(b.$1));
    return out;
  }

  Widget _note(SectionPalette palette, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: palette.textSecondary,
    ),
  );
}

/// Un número grande con su etiqueta.
class _Metric extends StatelessWidget {
  const _Metric({
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
    this.tone,
  });

  final SectionPalette palette;
  final String label;
  final String value;
  final IconData icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: palette.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tone ?? palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una sección y su barra de aciertos.
class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.palette, required this.stats});

  final SectionPalette palette;
  final SectionStats stats;

  @override
  Widget build(BuildContext context) {
    final percent = (stats.accuracy * 100).round();

    // El color acompaña, pero el número y el texto van siempre: un estado que
    // solo se distingue por color deja fuera a quien no lo ve.
    final tone = percent >= 70
        ? palette.success
        : (percent >= 45 ? palette.warning : palette.danger);

    return Semantics(
      label:
          '${stats.title}. $percent por ciento de aciertos. '
          '${stats.correct} de ${stats.answered} respuestas, '
          '${stats.students} estudiantes.',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stats.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent %',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: tone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
                child: LinearProgressIndicator(
                  value: stats.accuracy,
                  minHeight: 9,
                  backgroundColor: palette.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.correct} aciertos · ${stats.failed} fallos · '
                '${stats.students} '
                '${stats.students == 1 ? "estudiante" : "estudiantes"}'
                '${stats.avgSeconds == null ? "" : " · ${formatSeconds(stats.avgSeconds!)} de media"}',
                style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una pregunta difícil, con su enunciado.
/// Un tiempo en palabras: "48 s", "2 min 10 s".
String formatSeconds(double seconds) {
  final total = seconds.round();
  if (total < 60) return '$total s';

  final minutes = total ~/ 60;
  final rest = total % 60;
  return rest == 0 ? '$minutes min' : '$minutes min $rest s';
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.palette,
    required this.stats,
    this.showTime = false,
  });

  final SectionPalette palette;
  final QuestionStats stats;

  /// Enseña el tiempo medio en vez del porcentaje de aciertos.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final percent = (stats.accuracy * 100).round();
    final tone = percent >= 70
        ? palette.success
        : (percent >= 45 ? palette.warning : palette.danger);

    return Semantics(
      label:
          'Pregunta ${stats.questionIndex + 1} de ${stats.sectionTitle}. '
          '${stats.prompt}. Acertada el $percent por ciento de las veces, '
          '${stats.failed} fallos de ${stats.answered} respuestas.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(
                        SectionMetrics.pillRadius,
                      ),
                    ),
                    child: Text(
                      showTime && stats.avgSeconds != null
                          ? formatSeconds(stats.avgSeconds!)
                          : '$percent %',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stats.prompt.isEmpty
                          ? 'Pregunta ${stats.questionIndex + 1}'
                          : stats.prompt,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${stats.sectionTitle} · ${stats.failed} fallos de '
                '${stats.answered}'
                '${showTime ? "" : (stats.avgSeconds == null ? "" : " · ${formatSeconds(stats.avgSeconds!)}")}',
                style: TextStyle(fontSize: 11.5, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuántos terminan cada actividad de una sección.
class _CompletionRow extends StatelessWidget {
  const _CompletionRow({
    required this.palette,
    required this.title,
    required this.done,
  });

  final SectionPalette palette;
  final String title;
  final Map<String, int> done;

  /// El orden en que las hace el estudiante. Así se ve dónde abandona.
  static const List<(String, String, IconData)> _order = [
    ('lectura', 'Lectura', Icons.menu_book),
    ('capsula', 'Cápsula', Icons.lightbulb_outline),
    ('ejemplo', 'Ejemplo', Icons.code),
    ('ejercicio', 'Ejercicio', Icons.edit_note),
    ('video', 'Video', Icons.play_circle_outline),
    ('quiz', 'Quiz', Icons.quiz_outlined),
    ('laboratorio', 'Laboratorio', Icons.terminal),
    ('evaluacion', 'Evaluación', Icons.fact_check_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final parts = [
      for (final item in _order)
        if (done[item.$1] != null) (item, done[item.$1]!),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final most = parts.map((p) => p.$2).reduce((a, b) => a > b ? a : b);

    return Semantics(
      label:
          '$title. '
          '${parts.map((p) => "${p.$1.$2}: ${p.$2}").join(". ")}.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final part in parts)
                    Semantics(
                      excludeSemantics: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            part.$1.$3,
                            size: 17,
                            // Se apaga cuando mucha menos gente llega hasta
                            // aqui que al principio de la seccion.
                            color: part.$2 >= most
                                ? palette.accent
                                : palette.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${part.$2}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            part.$1.$2,
                            style: TextStyle(
                              fontSize: 10,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
