import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';

import 'section_activity_launcher.dart';
import 'section_theme.dart';
import 'section_widgets.dart';

/// Pantalla de un capítulo: su resumen y la ruta de actividades.
///
/// Es la misma para los seis módulos y los dos temas visuales. Lo que cambia
/// es el contenido que recibe, que sale del catálogo.
class ChapterSectionScreen extends StatefulWidget {
  const ChapterSectionScreen({
    super.key,
    required this.module,
    required this.section,
    this.onPreviousChapter,
    this.onNextChapter,
    this.trailingAction,
  });

  final CourseModule module;
  final CourseSection section;

  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  /// Acción extra en la cabecera, por ejemplo el lápiz de edición docente.
  final Widget? trailingAction;

  @override
  State<ChapterSectionScreen> createState() => _ChapterSectionScreenState();
}

class _ChapterSectionScreenState extends State<ChapterSectionScreen> {
  final CourseProgressStore _progress = CourseProgressStore.instance;
  final ScrollController _scrollController = ScrollController();

  late final List<CourseActivityKind> _activities;

  @override
  void initState() {
    super.initState();
    _activities = SectionActivityLauncher.activitiesFor(widget.section);
    _progress.addListener(_onProgressChanged);
    _progress.load();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  int get _completedCount =>
      _progress.completedCount(widget.section.id, _activities);

  double get _completionRatio =>
      _activities.isEmpty ? 0 : _completedCount / _activities.length;

  Future<void> _openActivity(CourseActivityKind kind) async {
    final completed = await SectionActivityLauncher.open(
      context,
      widget.module,
      widget.section,
      kind,
    );

    if (!mounted || !completed) return;

    announceForAccessibility(
      context,
      '${kind.label} completada. Llevas $_completedCount de '
      '${_activities.length} actividades de esta sección.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver al módulo',
        ),
        title: const Text(
          'CODE4ALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: palette.surfaceAlt,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              widget.module.label,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: SectionMetrics.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SectionMetrics.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(palette),
                        const SizedBox(height: SectionMetrics.sectionGap),
                        if (_activities.isEmpty)
                          SectionPendingContent(
                            sectionTitle: widget.section.title,
                            objectives: widget.section.objectives,
                          )
                        else
                          _buildActivityRoute(palette),
                        const SizedBox(height: SectionMetrics.sectionGap),
                        _buildChapterNav(palette),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: HelpActionButton(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SectionPalette palette) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeading(
                  title: widget.section.displayTitle,
                  subtitle: widget.section.summary,
                  icon: Icons.school_outlined,
                ),
              ),
              if (widget.trailingAction != null) ...[
                const SizedBox(width: 8),
                widget.trailingAction!,
              ],
            ],
          ),
          if (widget.section.objectives.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Objetivos de la sección',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            SectionList(items: widget.section.objectives, numbered: true),
          ],
          if (_activities.isNotEmpty) ...[
            const SizedBox(height: 18),
            SectionProgressBar(
              value: _completionRatio,
              label:
                  'Progreso: $_completedCount de ${_activities.length} '
                  'actividades completadas',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityRoute(SectionPalette palette) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: 'Ruta de actividades',
            subtitle:
                'Sigue el orden sugerido o entra directamente a la actividad '
                'que necesites.',
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _activities.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _activities.length - 1 ? 0 : 12,
              ),
              child: _ActivityTile(
                step: i + 1,
                kind: _activities[i],
                detail: SectionActivityLauncher.detailFor(
                  widget.section,
                  _activities[i],
                ),
                isCompleted: _progress.isCompleted(
                  widget.section.id,
                  _activities[i],
                ),
                onTap: () => _openActivity(_activities[i]),
              ),
            ),
          if (_completedCount == _activities.length) ...[
            const SizedBox(height: 18),
            SectionCallout(
              title: 'Sección completada',
              body:
                  '¡Felicitaciones! Terminaste las ${_activities.length} '
                  'actividades de "${widget.section.title}".',
              tone: SectionTone.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterNav(SectionPalette palette) {
    final hasPrevious = widget.onPreviousChapter != null;
    final hasNext = widget.onNextChapter != null;

    if (!hasPrevious && !hasNext) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: SectionSecondaryButton(
            label: 'Anterior',
            icon: Icons.skip_previous,
            semanticHint: hasPrevious
                ? 'Ir al capítulo anterior del módulo'
                : 'Este es el primer capítulo del módulo',
            onPressed: widget.onPreviousChapter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SectionPrimaryButton(
            label: 'Siguiente',
            icon: Icons.skip_next,
            semanticHint: hasNext
                ? 'Ir al capítulo siguiente del módulo'
                : 'Este es el último capítulo del módulo',
            onPressed: widget.onNextChapter,
          ),
        ),
      ],
    );
  }
}

/// Una fila de la ruta de actividades.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.step,
    required this.kind,
    required this.detail,
    required this.isCompleted,
    required this.onTap,
  });

  final int step;
  final CourseActivityKind kind;
  final String detail;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final activityColors = SectionActivityLauncher.colorsFor(context, kind);

    return Semantics(
      button: true,
      label: 'Paso $step. ${kind.label}. ${kind.description}. $detail',
      hint: isCompleted
          ? 'Ya completada. Púlsala para repasarla'
          : 'Pulsa para ${kind.actionLabel.toLowerCase()}',
      child: ExcludeSemantics(
        child: Material(
          color: isCompleted ? palette.successSoft : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: SectionMetrics.minTapTarget + 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
                border: Border.all(
                  color: isCompleted
                      ? palette.success.withValues(alpha: 0.55)
                      : palette.border,
                  width: isCompleted ? 1.8 : 1.2,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // En pantallas estrechas, o con el texto muy agrandado, la
                  // pildora de accion dejaria al titulo unos pocos pixeles.
                  // Ahi baja a su propia linea, a todo el ancho.
                  final stack = constraints.maxWidth < 300;

                  final icon = Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: activityColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: activityColors.foreground.withValues(
                          alpha: 0.35,
                        ),
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      SectionActivityLauncher.iconFor(kind),
                      size: 26,
                      color: activityColors.foreground,
                    ),
                  );

                  final texts = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paso $step · ${kind.label}',
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        kind.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: palette.textSecondary,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _DetailChip(
                          label: detail,
                          foreground: activityColors.foreground,
                          background: activityColors.background,
                        ),
                      ],
                    ],
                  );

                  final action = _TrailingAction(
                    kind: kind,
                    isCompleted: isCompleted,
                    color: activityColors.foreground,
                    fullWidth: stack,
                  );

                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            icon,
                            const SizedBox(width: 14),
                            Expanded(child: texts),
                          ],
                        ),
                        const SizedBox(height: 12),
                        action,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(child: texts),
                      const SizedBox(width: 10),
                      action,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.kind,
    required this.isCompleted,
    required this.color,
    this.fullWidth = false,
  });

  final CourseActivityKind kind;
  final bool isCompleted;
  final Color color;

  /// Ocupa todo el ancho cuando va en su propia linea.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    if (isCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 26, color: palette.success),
          const SizedBox(height: 4),
          Text(
            'Hecho',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: palette.success,
            ),
          ),
        ],
      );
    }

    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: BoxConstraints(
        minHeight: 36,
        maxWidth: fullWidth ? double.infinity : 120,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        kind.actionLabel,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          // Los colores de actividad son oscuros en tema claro y claros en
          // tema oscuro, así que el texto va siempre al contrario.
          color: palette.isDark ? const Color(0xFF0B1117) : Colors.white,
        ),
      ),
    );
  }
}

/// Chip con el detalle de la actividad, en su propio color.
class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
