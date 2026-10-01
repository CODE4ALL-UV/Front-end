import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';

/// Los cursos del estudiante: el general y los de sus docentes.
///
/// Cada docente edita su curso a su manera, así que el mismo tema puede estar
/// explicado distinto en dos cursos. Por eso se elige primero el curso y
/// después se estudia: el progreso de cada uno también va por separado.
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({
    super.key,
    required this.courseHome,
    this.userName,
    this.onLogout,
  });

  /// La pantalla del curso abierto (la ruta de módulos).
  final WidgetBuilder courseHome;
  final String? userName;
  final VoidCallback? onLogout;

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final MyCoursesStore _store = MyCoursesStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _open(CourseInfo course) async {
    await _store.select(course);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: widget.courseHome));
    // De vuelta en la lista: los números de estudiantes o el nombre del curso
    // pueden haber cambiado mientras se estudiaba.
    if (mounted) _store.refresh();
  }

  Future<void> _join() async {
    final joined = await showDialog<CourseInfo>(
      context: context,
      builder: (_) => const _JoinDialog(),
    );
    if (joined == null || !mounted) return;

    final message = 'Te uniste a ${joined.title}.';
    announceForAccessibility(context, message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _leave(CourseInfo course) async {
    final colors = context.colorScheme;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Salir de ${course.title}?'),
        content: const Text(
          'Tu avance se guarda. Para volver a entrar necesitarás otra vez el '
          'código de tu docente.',
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
            child: const Text('Salir del curso'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    try {
      await _store.leave(course);
      if (mounted) {
        announceForAccessibility(context, 'Saliste de ${course.title}.');
      }
    } on CourseActionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final courses = _store.courses;

    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Column(
        children: [
          const AccessibilityToolbar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _store.refresh,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
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
                            Semantics(
                              header: true,
                              child: Text(
                                'Mis cursos',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Elige en qué curso quieres estudiar. Si tu '
                              'docente te dio un código, úsalo para entrar a '
                              'su curso.',
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppMetrics.gap),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: _join,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  minimumSize: const Size(
                                    0,
                                    AppMetrics.minTapTarget,
                                  ),
                                ),
                                icon: const Icon(Icons.vpn_key_outlined),
                                label: const Text('Unirme a un curso'),
                              ),
                            ),
                            const SizedBox(height: AppMetrics.sectionGap),
                            for (final course in courses)
                              _CourseCard(
                                course: course,
                                onOpen: () => _open(course),
                                onLeave: course.isGeneral
                                    ? null
                                    : () => _leave(course),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onOpen, this.onLeave});

  final CourseInfo course;
  final VoidCallback onOpen;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primary,
                    child: Icon(
                      course.isGeneral ? Icons.public : Icons.school_outlined,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: true,
                    label:
                        '${course.title}. ${course.ownerLabel}. Toca para entrar.',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course.ownerLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (course.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (onLeave != null)
                  IconButton(
                    tooltip: 'Salir de ${course.title}',
                    onPressed: onLeave,
                    color: colors.onSurfaceVariant,
                    icon: const Icon(Icons.logout),
                  ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pide el código que dio el docente y entra al curso.
class _JoinDialog extends StatefulWidget {
  const _JoinDialog();

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final TextEditingController _code = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Escribe el código que te dio tu docente.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final course = await MyCoursesStore.instance.join(code);
      if (mounted) Navigator.of(context).pop(course);
    } on CourseActionException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
      announceForAccessibility(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return AlertDialog(
      title: const Text('Unirme a un curso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escribe el código de 6 letras y números que te dio tu docente.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppMetrics.gap),
          TextField(
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _send(),
            style: const TextStyle(fontSize: 20, letterSpacing: 3),
            decoration: InputDecoration(
              labelText: 'Código del curso',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: Text(_sending ? 'Entrando…' : 'Unirme'),
        ),
      ],
    );
  }
}
