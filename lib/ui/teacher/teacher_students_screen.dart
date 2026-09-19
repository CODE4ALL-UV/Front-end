import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'teacher_widgets.dart';

/// Los estudiantes del curso y cómo les va.
///
/// Salen todos, también quien no ha respondido nada. Esa es justo la
/// información que se pierde en un panel que solo enseña a quien participa:
/// el que no aparece es el que hay que buscar.
class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  final CourseAnalyticsStore _stats = CourseAnalyticsStore.instance;

  /// Orden: los que peor van primero, que son a quienes hay que atender.
  bool _strugglingFirst = true;

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

  List<StudentStats> get _ordered {
    final list = [..._stats.students];
    if (!_strugglingFirst) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    }

    list.sort((a, b) {
      // Quien no ha empezado va arriba del todo: es lo más urgente.
      if (a.hasNotStarted != b.hasNotStarted) return a.hasNotStarted ? -1 : 1;
      return a.accuracy.compareTo(b.accuracy);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    if (_stats.isLoading && !_stats.isLoaded) {
      return Center(
        child: CircularProgressIndicator(color: appTheme.actionBackground),
      );
    }

    if (_stats.problem != null) {
      return Padding(
        padding: const EdgeInsets.all(AppMetrics.gap),
        child: TeacherBanner(icon: Icons.cloud_off, text: _stats.problem!),
      );
    }

    final students = _ordered;

    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppMetrics.sectionGap),
          child: Text(
            'Todavía no hay ningún estudiante registrado en el curso.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: appTheme.textSubtitle,
            ),
          ),
        ),
      );
    }

    final sinEmpezar = students.where((s) => s.hasNotStarted).length;

    return RefreshIndicator(
      onRefresh: _stats.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppMetrics.pagePadding(constraints.maxWidth),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppMetrics.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${students.length} '
                              '${students.length == 1 ? "estudiante" : "estudiantes"}'
                              '${sinEmpezar > 0 ? " · $sinEmpezar sin empezar" : ""}',
                              style: TextStyle(
                                fontSize: 13,
                                color: appTheme.textSubtitle,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                              () => _strugglingFirst = !_strugglingFirst,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: appTheme.infoText,
                              minimumSize: const Size(
                                0,
                                AppMetrics.minTapTarget,
                              ),
                            ),
                            icon: const Icon(Icons.swap_vert, size: 18),
                            label: Text(
                              _strugglingFirst
                                  ? 'Por dificultad'
                                  : 'Por nombre',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppMetrics.gap),
                      for (final student in students)
                        _StudentRow(student: student),
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

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});

  final StudentStats student;

  @override
  Widget build(BuildContext context) {
    final percent = (student.accuracy * 100).round();
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    // final tone = student.hasNotStarted
    //     ? appTheme.textSubtitle
    //     : (percent >= 70
    //           ? appTheme.successBackground
    //           : (percent >= 45
    //                 ? appTheme.warningBackground
    //                 : appTheme.dangerBackground));

    final initials = student.name.trim().isEmpty
        ? '?'
        : student.name.trim()[0].toUpperCase();

    return Semantics(
      label: student.hasNotStarted
          ? '${student.name}. Todavía no ha empezado el curso.'
          : '${student.name}. ${student.activitiesDone} actividades '
                'terminadas'
                '${student.answered == 0 ? ", sin responder preguntas todavía" : ", $percent por ciento de aciertos en ${student.answered} respuestas"}.',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appTheme.iconBackground,
            border: Border.all(color: appTheme.border),
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: appTheme.dangerBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: appTheme.infoText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.name.isEmpty ? student.email : student.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: appTheme.textTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (student.hasNotStarted)
                      Row(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 13,
                            color: appTheme.textSubtitle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sin empezar',
                            style: TextStyle(
                              fontSize: 12,
                              color: appTheme.textSubtitle,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${student.activitiesDone} '
                        '${student.activitiesDone == 1 ? "actividad" : "actividades"}'
                        '${student.answered == 0 ? "" : " · ${student.correct} aciertos · ${student.failed} fallos"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: appTheme.textSubtitle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                student.hasNotStarted
                    ? '—'
                    : (student.answered == 0 ? '—' : '$percent %'),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
