import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'director_widgets.dart';
import 'teacher_detail_screen.dart';

/// Los docentes y cómo va su trabajo.
///
/// El orden no es alfabético a propósito: primero sale quien necesita algo de
/// la dirección. Alguien que lleva veinte ediciones y ninguna valoración es un
/// problema silencioso —trabaja y nadie le dice nada— y en una lista ordenada
/// por nombre se pierde entre los demás.
class DirectorTeachersScreen extends StatefulWidget {
  const DirectorTeachersScreen({super.key});

  @override
  State<DirectorTeachersScreen> createState() => _DirectorTeachersScreenState();
}

class _DirectorTeachersScreenState extends State<DirectorTeachersScreen> {
  final DirectorOversightStore _store = DirectorOversightStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    if (!_store.isLoaded) _store.refresh();
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Quien necesita atención primero.
  List<TeacherSummary> get _ordered {
    final list = [..._store.teachers];
    list.sort((a, b) {
      // Trabaja y nadie le ha dicho nada: lo más urgente.
      final aPending = a.edits > 0 && a.neverReviewed;
      final bPending = b.edits > 0 && b.neverReviewed;
      if (aPending != bPending) return aPending ? -1 : 1;

      // Luego, quien peor valorado está.
      final aScore = a.avgScore ?? 99;
      final bScore = b.avgScore ?? 99;
      if (aScore != bScore) return aScore.compareTo(bScore);

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
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

    final teachers = _ordered;
    if (teachers.isEmpty) {
      return DirectorEmpty(
        palette: palette,
        icon: Icons.person_off_outlined,
        title: 'No hay docentes registrados',
        body:
            'Cuando alguien se registre con rol docente aparecerá aquí, con '
            'todo lo que vaya haciendo en el curso.',
      );
    }

    final pending = _store.workingWithoutFeedback;

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
                      if (pending.isNotEmpty) ...[
                        DirectorNotice(
                          palette: palette,
                          icon: Icons.campaign_outlined,
                          title: pending.length == 1
                              ? 'Un docente espera tu respuesta'
                              : '${pending.length} docentes esperan tu respuesta',
                          body:
                              'Han editado el curso y todavía nadie les ha '
                              'dicho cómo lo están haciendo.',
                        ),
                        const SizedBox(height: SectionMetrics.gap),
                      ],
                      for (final teacher in teachers)
                        _TeacherCard(
                          palette: palette,
                          teacher: teacher,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TeacherDetailScreen(teacher: teacher),
                            ),
                          ),
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

/// Un docente, con lo que ha hecho y cómo está valorado.
class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.palette,
    required this.teacher,
    required this.onTap,
  });

  final SectionPalette palette;
  final TeacherSummary teacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsFeedback = teacher.edits > 0 && teacher.neverReviewed;

    return Semantics(
      button: true,
      label:
          '${teacher.name}. '
          '${teacher.edits} ediciones. '
          '${teacher.neverReviewed ? "Sin valorar todavía." : "Última nota ${teacher.lastScore} de 5, media ${teacher.avgScore}."}'
          '${needsFeedback ? " Espera tu respuesta." : ""}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    SectionMetrics.cardRadius,
                  ),
                  border: Border.all(
                    color: needsFeedback ? palette.warning : palette.border,
                    width: needsFeedback ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final avatar = CircleAvatar(
                          radius: 21,
                          backgroundColor: palette.accentSoft,
                          child: Text(
                            teacher.name.isEmpty
                                ? '?'
                                : teacher.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: palette.accent,
                            ),
                          ),
                        );

                        final identity = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              teacher.name.isEmpty
                                  ? teacher.email
                                  : teacher.name,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              teacher.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        );

                        final stars = ScoreStars(
                          palette: palette,
                          score: teacher.lastScore,
                        );

                        // Las cinco estrellas no se pueden encoger. En una
                        // pantalla estrecha, o con el texto agrandado, no caben
                        // al lado del nombre y hay que bajarlas.
                        if (constraints.maxWidth < 330) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  avatar,
                                  const SizedBox(width: 12),
                                  Expanded(child: identity),
                                ],
                              ),
                              const SizedBox(height: 8),
                              stars,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            avatar,
                            const SizedBox(width: 12),
                            Expanded(child: identity),
                            stars,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        DirectorBadge(
                          palette: palette,
                          icon: Icons.edit_outlined,
                          label: teacher.hasNotEdited
                              ? 'Sin editar nada'
                              : '${teacher.edits} '
                                    '${teacher.edits == 1 ? "edición" : "ediciones"}',
                          tone: teacher.hasNotEdited
                              ? palette.textSecondary
                              : null,
                        ),
                        if (teacher.lastEdit != null)
                          DirectorBadge(
                            palette: palette,
                            icon: Icons.schedule,
                            label: relativeDate(teacher.lastEdit!),
                          ),
                        DirectorBadge(
                          palette: palette,
                          icon: Icons.rate_review_outlined,
                          label: teacher.neverReviewed
                              ? 'Sin valorar'
                              : '${teacher.reviews} '
                                    '${teacher.reviews == 1 ? "valoración" : "valoraciones"}'
                                    '${teacher.avgScore == null ? "" : " · media ${teacher.avgScore}"}',
                          tone: needsFeedback ? palette.warning : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
