import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'director_widgets.dart';

/// Todo sobre un docente: lo que ha hecho y cómo se le ha valorado.
///
/// Las dos cosas van juntas a propósito. Poner una nota sin ver antes qué ha
/// tocado esa persona es evaluar a ciegas, y es justo lo que hace que una
/// evaluación no se la crea nadie.
class TeacherDetailScreen extends StatefulWidget {
  const TeacherDetailScreen({super.key, required this.teacher});

  final TeacherSummary teacher;

  @override
  State<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  final DirectorOversightStore _store = DirectorOversightStore.instance;

  List<TeacherEdit>? _edits;
  List<TeacherReview>? _reviews;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final edits = await _store.activityOf(widget.teacher.userId);
      final reviews = await _store.reviewsOf(widget.teacher.userId);
      if (!mounted) return;

      setState(() {
        _edits = edits;
        _reviews = reviews;
        _problem = null;
      });
    } on OversightException catch (e) {
      if (mounted) setState(() => _problem = e.message);
    } catch (_) {
      if (mounted) setState(() => _problem = 'No se pudo consultar.');
    }
  }

  Future<void> _openReviewSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SectionPalette.of(context).surface,
      builder: (_) => _ReviewSheet(teacher: widget.teacher),
    );

    if (saved == true && mounted) {
      announceForAccessibility(context, 'Valoración guardada.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final teacher = widget.teacher;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: palette.onAccent,
        title: Text(teacher.name.isEmpty ? 'Docente' : teacher.name),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: UserProfileMenu(showName: false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReviewSheet,
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Valorar'),
      ),
      body: SafeArea(
        child: _problem != null
            ? DirectorProblem(
                palette: palette,
                message: _problem!,
                onRetry: _load,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    padding: SectionMetrics.pagePadding(constraints.maxWidth),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: SectionMetrics.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _body(palette, teacher),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  List<Widget> _body(SectionPalette palette, TeacherSummary teacher) {
    final edits = _edits;
    final reviews = _reviews;

    return [
      // --- quién es y cómo va ---------------------------------------------
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: palette.accentSoft,
              child: Text(
                teacher.name.isEmpty ? '?' : teacher.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    teacher.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  ScoreStars(palette: palette, score: teacher.lastScore),
                ],
              ),
            ),
          ],
        ),
      ),

      if (teacher.edits > 0 && teacher.neverReviewed) ...[
        const SizedBox(height: SectionMetrics.gap),
        DirectorNotice(
          palette: palette,
          icon: Icons.campaign_outlined,
          title: 'Todavía no le has dicho nada',
          body:
              'Ha editado el curso ${teacher.edits} '
              '${teacher.edits == 1 ? "vez" : "veces"} y no tiene ninguna '
              'valoración.',
        ),
      ],

      const SizedBox(height: SectionMetrics.sectionGap),
      _title(palette, 'Qué ha hecho', Icons.history),
      const SizedBox(height: 6),
      _note(
        palette,
        'Sale de sus propias ediciones guardadas, no de lo que diga nadie.',
      ),
      const SizedBox(height: SectionMetrics.gap),

      if (edits == null)
        Center(child: CircularProgressIndicator(color: palette.accent))
      else if (edits.isEmpty)
        _note(palette, 'Todavía no ha editado nada del temario.')
      else
        for (final edit in edits) _EditRow(palette: palette, edit: edit),

      const SizedBox(height: SectionMetrics.sectionGap),
      _title(palette, 'Valoraciones', Icons.rate_review_outlined),
      const SizedBox(height: 6),
      _note(
        palette,
        'Se guarda el histórico: así se ve si mejora, que es para lo que '
        'sirve valorar a alguien.',
      ),
      const SizedBox(height: SectionMetrics.gap),

      if (reviews == null)
        Center(child: CircularProgressIndicator(color: palette.accent))
      else if (reviews.isEmpty)
        _note(palette, 'Todavía no se le ha valorado.')
      else
        for (final review in reviews)
          _ReviewRow(palette: palette, review: review),

      const SizedBox(height: 90),
    ];
  }

  Widget _title(SectionPalette palette, String text, IconData icon) => Row(
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

  Widget _note(SectionPalette palette, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: palette.textSecondary,
    ),
  );
}

/// Una edición del docente, con el estado de su revisión.
class _EditRow extends StatelessWidget {
  const _EditRow({required this.palette, required this.edit});

  final SectionPalette palette;
  final TeacherEdit edit;

  @override
  Widget build(BuildContext context) {
    final status = edit.reviewStatus;

    return Semantics(
      label:
          '${edit.title}. '
          '${edit.updatedAt == null ? "" : "Cambiado ${relativeDate(edit.updatedAt!)}. "}'
          '${status == null ? "Sin revisar." : (edit.reviewOutdated ? "Revisado antes de este cambio, la revisión ya no vale." : "Revisado: $status.")}',
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
                children: [
                  Icon(
                    edit.scope == 'module'
                        ? Icons.folder_outlined
                        : Icons.article_outlined,
                    size: 17,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      edit.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  if (edit.updatedAt != null)
                    Text(
                      relativeDate(edit.updatedAt!),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (status == null)
                DirectorBadge(
                  palette: palette,
                  icon: Icons.pending_outlined,
                  label: 'Sin revisar',
                )
              else if (edit.reviewOutdated)
                // Lo aprobado antes del cambio no dice nada de lo que hay
                // ahora. Callarlo dejaria un visto bueno enganoso.
                DirectorBadge(
                  palette: palette,
                  icon: Icons.update,
                  label: 'Revisado antes de este cambio',
                  tone: palette.warning,
                )
              else
                DirectorBadge(
                  palette: palette,
                  icon: status == 'aprobado'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  label: status == 'aprobado'
                      ? 'Aprobado'
                      : 'Con observaciones',
                  tone: status == 'aprobado' ? palette.success : palette.danger,
                ),
              if ((edit.reviewComment ?? '').isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  edit.reviewComment!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Una valoración pasada.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.palette, required this.review});

  final SectionPalette palette;
  final TeacherReview review;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Nota ${review.score} de 5'
          '${review.createdAt == null ? "" : ", ${relativeDate(review.createdAt!)}"}. '
          '${review.comment}',
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
                children: [
                  ScoreStars(palette: palette, score: review.score),
                  const Spacer(),
                  if (review.createdAt != null)
                    Text(
                      relativeDate(review.createdAt!),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textSecondary,
                      ),
                    ),
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  review.comment,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// El formulario para valorar: nota y comentario.
class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.teacher});

  final TeacherSummary teacher;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _comment = TextEditingController();

  int _score = 4;
  bool _saving = false;
  String? _error;

  static const Map<int, String> _meaning = {
    1: 'Necesita apoyo urgente',
    2: 'Por debajo de lo esperado',
    3: 'Cumple',
    4: 'Buen trabajo',
    5: 'Excelente',
  };

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final comment = _comment.text.trim();
    if (comment.isEmpty) {
      // Una nota sin explicacion no le dice al docente que hacer distinto.
      setState(
        () => _error = 'Escribe un comentario: la nota sola no explica nada.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await DirectorOversightStore.instance.review(
        userId: widget.teacher.userId,
        score: _score,
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
        // Deja sitio al teclado: si no, el comentario queda tapado justo
        // mientras se escribe.
        bottom: MediaQuery.viewInsetsOf(context).bottom + SectionMetrics.gap,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Valorar a ${widget.teacher.name}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: SectionMetrics.sectionGap),

            Text(
              'Nota',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= 5; i++)
                  Semantics(
                    button: true,
                    selected: _score == i,
                    label: '$i de 5, ${_meaning[i]}',
                    child: ExcludeSemantics(
                      child: IconButton(
                        onPressed: () => setState(() => _score = i),
                        iconSize: 34,
                        constraints: const BoxConstraints(
                          minWidth: SectionMetrics.minTapTarget,
                          minHeight: SectionMetrics.minTapTarget,
                        ),
                        icon: Icon(
                          i <= _score
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i <= _score ? palette.warning : palette.border,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Center(
              child: Text(
                _meaning[_score]!,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: SectionMetrics.sectionGap),
            Text(
              'Comentario',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _comment,
              maxLines: 5,
              minLines: 3,
              onChanged: (_) => setState(() => _error = null),
              style: TextStyle(fontSize: 14.5, color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Qué está haciendo bien y qué puede mejorar',
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
            const SizedBox(height: 6),
            Text(
              'Es lo que de verdad le sirve: la nota sola no dice qué hacer '
              'distinto.',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
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
