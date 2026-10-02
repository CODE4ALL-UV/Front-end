import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_quick_button.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_stats_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';
import 'director_content_screen.dart';
import 'director_teachers_screen.dart';

/// Lo que ve la dirección al entrar.
///
/// Cuatro preguntas distintas, cada una en su sitio: cómo va el curso, cómo
/// van los estudiantes, qué hace cada docente y si el contenido está revisado.
/// Juntarlas en una sola pantalla obligaría a leerlo todo para encontrar una
/// cosa.
///
/// Las dos primeras pestañas son las mismas que ve el docente, no una copia:
/// los datos son los mismos y mantener dos versiones acabaría con una de las
/// dos desactualizada.
class DirectorHomeScreen extends StatefulWidget {
  const DirectorHomeScreen({
    super.key,
    this.userName = 'Dirección',
    this.onLogout,
  });

  final String userName;
  final VoidCallback? onLogout;

  @override
  State<DirectorHomeScreen> createState() => _DirectorHomeScreenState();
}

class _DirectorHomeScreenState extends State<DirectorHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final DirectorOversightStore _store = DirectorOversightStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    _store.refresh();
    // Para el filtro por curso de las estadísticas.
    final courses = MyCoursesStore.instance;
    if (courses.supported == null) courses.refresh();
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Abre el editor sobre el Curso general.
  ///
  /// Con cursos por docente, el curso de todos solo lo edita la
  /// coordinación: los docentes editan los suyos.
  Future<void> _editGeneralCourse() async {
    final courses = MyCoursesStore.instance;
    final stats = CourseAnalyticsStore.instance;
    // El curso que estaba mirando en las estadísticas, para dejarlo igual
    // al volver: el filtro de arriba lo sigue mostrando.
    final filtered = stats.courseId;
    if (courses.supported == null) await courses.refresh();
    final general = courses.courses.where((c) => c.isGeneral).firstOrNull;
    await courses.select(general);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherCourseScreen(
          userName: widget.userName,
          onLogout: widget.onLogout,
          course: general,
        ),
      ),
    );
    await courses.select(null);
    stats.useCourse(filtered);
    stats.refresh();
    _store.refresh();
  }

  /// Cuántas cosas piden atención, para avisarlo en la propia pestaña.
  int get _pendingTeachers => _store.workingWithoutFeedback.length;
  int get _pendingContent =>
      _store.flagged.length + _store.outdatedApprovals.length;

  @override
  Widget build(BuildContext context) {
    final appColorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: appColorScheme.surface,
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
        extraActions: [
          IconButton(
            tooltip: 'Editar el curso general',
            onPressed: _editGeneralCourse,
            color: appColorScheme.onPrimary,
            icon: const Icon(Icons.edit_note),
          ),
          const AccessibilityQuickButton(),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            const Tab(icon: Icon(Icons.insights), text: 'Curso'),
            const Tab(icon: Icon(Icons.groups_outlined), text: 'Estudiantes'),
            _TabWithCount(
              icon: Icons.school_outlined,
              label: 'Docentes',
              count: _pendingTeachers,
            ),
            _TabWithCount(
              icon: Icons.fact_check_outlined,
              label: 'Contenido',
              count: _pendingContent,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: const [
            _WithCourseFilter(child: TeacherStatsScreen()),
            _WithCourseFilter(child: TeacherStudentsScreen()),
            DirectorTeachersScreen(),
            DirectorContentScreen(),
          ],
        ),
      ),
    );
  }
}

/// Una pestaña con un contador de cosas pendientes.
class _TabWithCount extends StatelessWidget {
  const _TabWithCount({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final appColorScheme = context.colorScheme;

    return Tab(
      icon: count == 0
          ? Icon(icon)
          : Badge(
              label: Text('$count'),
              // Sobre la barra: el color de su texto de fondo y el de la
              // barra para el número, que contrastan en los seis temas.
              backgroundColor: appColorScheme.onPrimary,
              textColor: appColorScheme.primary,
              child: Icon(icon),
            ),
      // El contador también se dice, no solo se pinta: un número en rojo que
      // no se lee en voz alta no existe para quien navega por voz.
      text: count == 0
          ? label
          : '$label ($count ${count == 1 ? "pendiente" : "pendientes"})',
    );
  }
}

/// Las estadísticas con un selector de curso encima.
///
/// La coordinación ve por defecto todos los cursos juntos, que sirve para
/// saber cómo va Code4All en general. Para saber cómo va el grupo de un
/// docente concreto hay que poder mirar solo ese curso.
class _WithCourseFilter extends StatelessWidget {
  const _WithCourseFilter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CourseFilter(),
        Expanded(child: child),
      ],
    );
  }
}

/// El selector. Guarda su propia elección en vez de escuchar a las
/// estadísticas: estas avisan de que empiezan a cargar justo mientras se
/// construye su pestaña, y redibujar el selector en ese momento rompe.
class _CourseFilter extends StatefulWidget {
  const _CourseFilter();

  @override
  State<_CourseFilter> createState() => _CourseFilterState();
}

class _CourseFilterState extends State<_CourseFilter> {
  final MyCoursesStore _courses = MyCoursesStore.instance;
  int? _selected = CourseAnalyticsStore.instance.courseId;

  @override
  void initState() {
    super.initState();
    _courses.addListener(_onChanged);
  }

  @override
  void dispose() {
    _courses.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _choose(int? courseId) async {
    setState(() => _selected = courseId);
    final stats = CourseAnalyticsStore.instance;
    stats.useCourse(courseId);
    await stats.refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Con el servidor de antes no hay cursos que elegir.
    if (_courses.supported != true || _courses.courses.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colorScheme;
    final known = _courses.courses.any((c) => c.id == _selected);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppMetrics.maxContentWidth + 40,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label: 'Ver las estadísticas de',
                    child: DropdownButton<int?>(
                      isExpanded: true,
                      value: known ? _selected : null,
                      underline: const SizedBox.shrink(),
                      onChanged: _choose,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos los cursos'),
                        ),
                        for (final course in _courses.courses)
                          DropdownMenuItem<int?>(
                            value: course.id,
                            child: Text(
                              course.isGeneral || course.teacherName == null
                                  ? course.title
                                  : '${course.title} · ${course.teacherName}',
                              overflow: TextOverflow.ellipsis,
                            ),
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
    );
  }
}
