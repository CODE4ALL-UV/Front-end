import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_quick_button.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';

/// Los cursos del docente.
///
/// Cada uno es una copia del curso de Python que el docente edita a su
/// manera, con sus propios estudiantes. Lo que cambia en uno no toca a los
/// demás, ni a los cursos de otros docentes.
class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({
    super.key,
    required this.courseEditor,
    this.userName,
    this.onLogout,
  });

  /// La pantalla para editar el curso abierto (temario, estadísticas y
  /// estudiantes).
  final Widget Function(BuildContext context, CourseInfo course) courseEditor;
  final String? userName;
  final VoidCallback? onLogout;

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
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

  void _say(String message) {
    announceForAccessibility(context, message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(CourseInfo course) async {
    await _store.select(course);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => widget.courseEditor(context, course),
      ),
    );
    if (mounted) _store.refresh();
  }

  Future<void> _create() async {
    final created = await showDialog<CourseInfo>(
      context: context,
      builder: (_) =>
          _CreateCourseDialog(canCopyGeneral: _store.generalCourseId != null),
    );
    if (created != null && mounted) {
      _say(
        'Curso ${created.title} creado. Su código es ${created.joinCode ?? ''}.',
      );
    }
  }

  Future<void> _rename(CourseInfo course) async {
    final renamed = await showDialog<CourseInfo>(
      context: context,
      builder: (_) => _RenameCourseDialog(course: course),
    );
    if (renamed != null && mounted) {
      _say('El curso ahora se llama ${renamed.title}.');
    }
  }

  Future<void> _copyCode(CourseInfo course) async {
    final code = course.joinCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) _say('Código $code copiado.');
  }

  Future<void> _renewCode(CourseInfo course) async {
    final sure = await _confirm(
      title: '¿Cambiar el código de ${course.title}?',
      body:
          'El código actual dejará de servir para entrar. Quien ya está '
          'inscrito sigue en el curso.',
      action: 'Cambiar código',
    );
    if (!sure) return;
    try {
      final renewed = await _store.renewCode(course);
      if (mounted) _say('Nuevo código: ${renewed.joinCode ?? ''}.');
    } on CourseActionException catch (e) {
      if (mounted) _say(e.message);
    }
  }

  Future<void> _delete(CourseInfo course) async {
    final sure = await _confirm(
      title: '¿Borrar ${course.title}?',
      body: 'Se borran también las secciones que editaste en él.',
      action: 'Borrar curso',
      danger: true,
    );
    if (!sure) return;
    try {
      await _store.delete(course);
      if (mounted) _say('Curso ${course.title} borrado.');
    } on CourseActionException catch (e) {
      if (mounted) _say(e.message);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool danger = false,
  }) async {
    final colors = context.colorScheme;
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: danger ? colors.error : colors.primary,
              foregroundColor: danger ? colors.onError : colors.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final courses = _store.courses;

    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
        extraActions: const [AccessibilityQuickButton()],
      ),
      body: RefreshIndicator(
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
                        'Cada curso tiene su propio temario editado y sus propios '
                        'estudiantes. Lo que cambies en uno no toca a los demás. '
                        'Comparte el código para que tus estudiantes entren.',
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
                          onPressed: _create,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            minimumSize: const Size(0, AppMetrics.minTapTarget),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear curso'),
                        ),
                      ),
                      const SizedBox(height: AppMetrics.sectionGap),
                      if (courses.isEmpty)
                        Text(
                          'Todavía no tienes cursos. Crea el primero: empieza con '
                          'el temario de Code4All y lo cambias a tu manera.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      for (final course in courses)
                        _TeacherCourseCard(
                          course: course,
                          onOpen: () => _open(course),
                          onRename: () => _rename(course),
                          onCopyCode: () => _copyCode(course),
                          onRenewCode: () => _renewCode(course),
                          onDelete: (course.students ?? 0) == 0
                              ? () => _delete(course)
                              : null,
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherCourseCard extends StatelessWidget {
  const _TeacherCourseCard({
    required this.course,
    required this.onOpen,
    required this.onRename,
    required this.onCopyCode,
    required this.onRenewCode,
    this.onDelete,
  });

  final CourseInfo course;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onCopyCode;
  final VoidCallback onRenewCode;

  /// Solo si el curso no tiene estudiantes todavía.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final students = course.students ?? 0;
    final code = course.joinCode ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          if (course.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              course.description,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            students == 1 ? '1 estudiante' : '$students estudiantes',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          // El código va grande y espaciado: se dicta en clase o se copia de
          // la pizarra, y una letra confundida deja a alguien fuera.
          Semantics(
            label: 'Código para inscribirse: ${code.split('').join(' ')}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              // Wrap y no Row: con la letra grande o en un celular estrecho
              // el código baja a su propia línea en vez de salirse.
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Código: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SelectableText(
                    code,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(0, AppMetrics.minTapTarget),
                ),
                icon: const Icon(Icons.edit_note),
                label: const Text('Abrir y editar'),
              ),
              OutlinedButton.icon(
                onPressed: onCopyCode,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppMetrics.minTapTarget),
                ),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar código'),
              ),
              TextButton.icon(
                onPressed: onRename,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppMetrics.minTapTarget),
                ),
                icon: const Icon(Icons.drive_file_rename_outline, size: 18),
                label: const Text('Renombrar'),
              ),
              TextButton.icon(
                onPressed: onRenewCode,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppMetrics.minTapTarget),
                ),
                icon: const Icon(Icons.autorenew, size: 18),
                label: const Text('Nuevo código'),
              ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.error,
                    minimumSize: const Size(0, AppMetrics.minTapTarget),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Borrar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nombre, descripción y con qué empieza el curso nuevo.
class _CreateCourseDialog extends StatefulWidget {
  const _CreateCourseDialog({required this.canCopyGeneral});

  final bool canCopyGeneral;

  @override
  State<_CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _copyGeneral = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(
        () => _error = 'Ponle un nombre al curso, por ejemplo «Python 2026-1».',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final course = await MyCoursesStore.instance.create(
        title: title,
        description: _description.text.trim(),
        copyGeneral: _copyGeneral,
      );
      if (mounted) Navigator.of(context).pop(course);
    } on CourseActionException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
      announceForAccessibility(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return AlertDialog(
      title: const Text('Crear curso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'Nombre del curso',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              minLines: 2,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Para quién es, horario, grupo…',
              ),
            ),
            if (widget.canCopyGeneral)
              CheckboxListTile(
                value: _copyGeneral,
                onChanged: (value) =>
                    setState(() => _copyGeneral = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Empezar con lo editado en el curso general'),
                subtitle: Text(
                  'Si no, empieza con el temario original de Code4All.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: Text(_saving ? 'Creando…' : 'Crear'),
        ),
      ],
    );
  }
}

/// Cambiar el nombre y la descripción de un curso.
///
/// Los estudiantes lo ven con el nombre nuevo en «Mis cursos»; el código y lo
/// editado no cambian.
class _RenameCourseDialog extends StatefulWidget {
  const _RenameCourseDialog({required this.course});

  final CourseInfo course;

  @override
  State<_RenameCourseDialog> createState() => _RenameCourseDialogState();
}

class _RenameCourseDialogState extends State<_RenameCourseDialog> {
  late final TextEditingController _title = TextEditingController(
    text: widget.course.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.course.description,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'El curso necesita un nombre.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final course = await MyCoursesStore.instance.update(
        widget.course,
        title: title,
        description: _description.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(course);
    } on CourseActionException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
      announceForAccessibility(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return AlertDialog(
      title: const Text('Renombrar curso'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'Nombre del curso',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              minLines: 2,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
