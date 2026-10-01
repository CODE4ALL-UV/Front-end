import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
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

  /// Sacar a alguien solo tiene sentido en un curso propio: del Curso general
  /// no se saca a nadie, y la coordinación mira a todos juntos.
  bool get _canRemove {
    final course = MyCoursesStore.instance.active;
    return course != null && !course.isGeneral && course.isOwner;
  }

  Future<void> _remove(StudentStats student) async {
    final course = MyCoursesStore.instance.active;
    if (course == null) return;
    final name = student.name.isEmpty ? student.email : student.name;
    final colors = context.colorScheme;

    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Sacar a $name de ${course.title}?'),
        content: const Text(
          'Dejará de ver el curso. Su avance se guarda: si vuelve a entrar '
          'con el código, lo recupera.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sacar del curso'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    try {
      await MyCoursesStore.instance.removeStudent(course, student.userId);
      await _stats.refresh();
      if (!mounted) return;
      final message = '$name ya no está en ${course.title}.';
      announceForAccessibility(context, message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on CourseActionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
    final appColorScheme = context.colorScheme;

    if (_stats.isLoading && !_stats.isLoaded) {
      return const Center(child: CircularProgressIndicator());
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
              color: appColorScheme.onSurfaceVariant,
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
                                color: appColorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                              () => _strugglingFirst = !_strugglingFirst,
                            ),
                            style: TextButton.styleFrom(
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
                        _StudentRow(
                          student: student,
                          onRemove: _canRemove ? () => _remove(student) : null,
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

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, this.onRemove});

  final StudentStats student;

  /// Sacarlo del curso. Nulo donde no se puede (el Curso general, o quien no
  /// es su docente).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final percent = (student.accuracy * 100).round();
    final appColorScheme = context.colorScheme;
    final appSemanticColors = context.messageColors;

    final tone = student.hasNotStarted
        ? appColorScheme.onSurfaceVariant
        : (percent >= 70
              ? appSemanticColors.successForeground
              : (percent >= 45
                    ? appSemanticColors.warningForeground
                    : appSemanticColors.dangerForeground));

    final initials = student.name.trim().isEmpty
        ? '?'
        : student.name.trim()[0].toUpperCase();

    final label = student.hasNotStarted
        ? '${student.name}. Todavía no ha empezado el curso.'
        : '${student.name}. ${student.activitiesDone} actividades '
              'terminadas'
              '${student.answered == 0 ? ", sin responder preguntas todavía" : ", $percent por ciento de aciertos en ${student.answered} respuestas"}.';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColorScheme.surface,
        border: Border.all(color: appColorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: label,
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: appColorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: appColorScheme.onSurface,
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
                              color: appColorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (student.hasNotStarted)
                            Row(
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  size: 13,
                                  color: appColorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sin empezar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: appColorScheme.onSurfaceVariant,
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
                                color: appColorScheme.onSurfaceVariant,
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip:
                  'Sacar a ${student.name.isEmpty ? student.email : student.name} del curso',
              onPressed: onRemove,
              color: appColorScheme.onSurfaceVariant,
              constraints: const BoxConstraints(
                minWidth: AppMetrics.minTapTarget,
                minHeight: AppMetrics.minTapTarget,
              ),
              icon: const Icon(Icons.person_remove_outlined),
            ),
        ],
      ),
    );
  }
}
