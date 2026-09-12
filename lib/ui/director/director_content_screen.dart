import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'director_widgets.dart';

/// Revisar que el contenido del curso esté bien.
///
/// Solo salen las secciones que **el docente ha editado**. El material de
/// fábrica no necesita revisión de nadie; lo que hay que mirar es lo que
/// alguien cambió. Revisar dieciocho secciones intactas sería trabajo inútil.
class DirectorContentScreen extends StatefulWidget {
  const DirectorContentScreen({super.key});

  @override
  State<DirectorContentScreen> createState() => _DirectorContentScreenState();
}

class _DirectorContentScreenState extends State<DirectorContentScreen> {
  final DirectorOversightStore _store = DirectorOversightStore.instance;
  final CourseContentStore _content = CourseContentStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    _content.addListener(_onChanged);
    if (!_store.isLoaded) _store.refresh();
    _content.refresh();
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    _content.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Las secciones editadas por el docente, que son las que hay que revisar.
  List<CourseSection> get _edited {
    final out = <CourseSection>[];
    for (final module in PythonCourseCatalog.modules) {
      for (final section in module.sections) {
        if (_content.isSectionEdited(section.id)) {
          out.add(_content.section(module.number, section.number) ?? section);
        }
      }
    }
    return out;
  }

  Future<void> _judge(CourseSection section) async {
    final verdict = _store.verdictOf(section.id);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SectionPalette.of(context).surface,
      builder: (_) => _JudgeSheet(section: section, current: verdict),
    );

    if (saved == true && mounted) {
      announceForAccessibility(context, 'Revisión guardada.');
    }
  }

  void _preview(CourseSection section) {
    final module = PythonCourseCatalog.moduleByNumber(section.moduleNumber)!;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterSectionScreen(
          module: CourseModule(
            number: module.number,
            title: _content.moduleTitle(module.number, module.title),
            sections: module.sections,
          ),
          section: section,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    if (_store.isLoading && !_store.isLoaded) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    if (_store.problem != null) {
      return DirectorProblem(
        palette: palette,
        message: _store.problem!,
        onRetry: _store.refresh,
      );
    }

    final edited = _edited;
    if (edited.isEmpty) {
      return DirectorEmpty(
        palette: palette,
        icon: Icons.fact_check_outlined,
        title: 'No hay nada que revisar',
        body:
            'Aquí aparecen solo las secciones que un docente haya cambiado. '
            'El material original del curso no necesita revisión.',
      );
    }

    final outdated = _store.outdatedApprovals;
    final flagged = _store.flagged;

    return RefreshIndicator(
      onRefresh: _store.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: SectionMetrics.pagePadding(constraints.maxWidth),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SectionMetrics.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (outdated.isNotEmpty) ...[
                        DirectorNotice(
                          palette: palette,
                          icon: Icons.update,
                          title: outdated.length == 1
                              ? 'Una aprobación se quedó vieja'
                              : '${outdated.length} aprobaciones se quedaron viejas',
                          body:
                              'El docente cambió esas secciones después de que '
                              'las aprobaras, así que tu visto bueno ya no dice '
                              'nada del contenido que hay ahora.',
                        ),
                        const SizedBox(height: SectionMetrics.gap),
                      ],
                      if (flagged.isNotEmpty) ...[
                        DirectorNotice(
                          palette: palette,
                          icon: Icons.error_outline,
                          tone: palette.danger,
                          title: flagged.length == 1
                              ? 'Una sección con observaciones'
                              : '${flagged.length} secciones con observaciones',
                          body: 'Pendientes de que el docente las corrija.',
                        ),
                        const SizedBox(height: SectionMetrics.gap),
                      ],
                      for (final section in edited)
                        _SectionCard(
                          palette: palette,
                          section: section,
                          verdict: _store.verdictOf(section.id),
                          onJudge: () => _judge(section),
                          onPreview: () => _preview(section),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.section,
    required this.verdict,
    required this.onJudge,
    required this.onPreview,
  });

  final SectionPalette palette;
  final CourseSection section;
  final ContentVerdict? verdict;
  final VoidCallback onJudge;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final current = verdict;

    final (String label, IconData icon, Color tone) = current == null
        ? ('Sin revisar', Icons.pending_outlined, palette.textSecondary)
        : current.outdated
        ? ('Revisado antes del último cambio', Icons.update, palette.warning)
        : current.isApproved
        ? ('Aprobado', Icons.check_circle_outline, palette.success)
        : ('Con observaciones', Icons.error_outline, palette.danger);

    return Semantics(
      label:
          'Módulo ${section.moduleNumber}, ${section.title}. $label.'
          '${(current?.comment ?? '').isEmpty ? '' : ' ${current!.comment}'}',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            border: Border.all(
              color: current == null || current.outdated || !current.isApproved
                  ? tone.withValues(alpha: 0.45)
                  : palette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Módulo ${section.moduleNumber} · Sección ${section.number}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          section.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, size: 22, color: tone),
                ],
              ),
              const SizedBox(height: 10),
              DirectorBadge(
                palette: palette,
                icon: icon,
                label: label,
                tone: tone,
              ),
              if ((current?.comment ?? '').isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    current!.comment,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPreview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.accent,
                        side: BorderSide(color: palette.border),
                        minimumSize: const Size(0, SectionMetrics.minTapTarget),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Ver'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onJudge,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.onAccent,
                        minimumSize: const Size(0, SectionMetrics.minTapTarget),
                      ),
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      label: Text(current == null ? 'Revisar' : 'Cambiar'),
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

/// Aprobar u observar una sección.
class _JudgeSheet extends StatefulWidget {
  const _JudgeSheet({required this.section, required this.current});

  final CourseSection section;
  final ContentVerdict? current;

  @override
  State<_JudgeSheet> createState() => _JudgeSheetState();
}

class _JudgeSheetState extends State<_JudgeSheet> {
  late final TextEditingController _comment = TextEditingController(
    text: widget.current?.comment ?? '',
  );

  late bool _approved = widget.current?.isApproved ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final comment = _comment.text.trim();

    // Observar sin decir que esta mal deja al docente sin saber que tocar.
    if (!_approved && comment.isEmpty) {
      setState(() => _error = 'Si pones observaciones, explica cuáles.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await DirectorOversightStore.instance.judgeContent(
        sectionId: widget.section.id,
        approved: _approved,
        comment: comment,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on OversightException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: SectionMetrics.gap,
        right: SectionMetrics.gap,
        top: SectionMetrics.gap,
        bottom: MediaQuery.viewInsetsOf(context).bottom + SectionMetrics.gap,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Revisar "${widget.section.title}"',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: SectionMetrics.sectionGap),

            Row(
              children: [
                Expanded(
                  child: _Choice(
                    palette: palette,
                    icon: Icons.check_circle_outline,
                    label: 'Aprobado',
                    tone: palette.success,
                    selected: _approved,
                    onTap: () => setState(() {
                      _approved = true;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Choice(
                    palette: palette,
                    icon: Icons.error_outline,
                    label: 'Con observaciones',
                    tone: palette.danger,
                    selected: !_approved,
                    onTap: () => setState(() => _approved = false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: SectionMetrics.sectionGap),
            TextField(
              controller: _comment,
              maxLines: 5,
              minLines: 3,
              onChanged: (_) => setState(() => _error = null),
              style: TextStyle(fontSize: 14.5, color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: _approved
                    ? 'Comentario (opcional)'
                    : 'Qué hay que corregir',
                hintText: _approved
                    ? 'Puedes dejarlo vacío'
                    : 'Explica qué está mal para que pueda arreglarlo',
                hintStyle: TextStyle(color: palette.textSecondary),
                filled: true,
                fillColor: palette.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    SectionMetrics.cardRadius,
                  ),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: SectionMetrics.gap),
              Text(
                _error!,
                style: TextStyle(fontSize: 13, color: palette.danger),
              ),
            ],

            const SizedBox(height: SectionMetrics.sectionGap),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, SectionMetrics.minTapTarget),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent,
                      minimumSize: const Size(0, SectionMetrics.minTapTarget),
                    ),
                    child: Text(_saving ? 'Guardando…' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.palette,
    required this.icon,
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final SectionPalette palette;
  final IconData icon;
  final String label;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tone.withValues(alpha: 0.12) : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: SectionMetrics.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
                border: Border.all(
                  color: selected ? tone : palette.border,
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? tone : palette.textSecondary,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? tone : palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
