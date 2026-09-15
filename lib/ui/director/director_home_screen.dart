import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';
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

  /// Cuántas cosas piden atención, para avisarlo en la propia pestaña.
  int get _pendingTeachers => _store.workingWithoutFeedback.length;
  int get _pendingContent =>
      _store.flagged.length + _store.outdatedApprovals.length;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;

    return Scaffold(
      backgroundColor: appTheme.background,
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
            TeacherStatsScreen(),
            TeacherStudentsScreen(),
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
    return Tab(
      icon: count == 0
          ? Icon(icon)
          : Badge(
              label: Text('$count'),
              backgroundColor: Colors.white,
              textColor: const Color(0xFFC62828),
              child: Icon(icon),
            ),
      // El contador también se dice, no solo se pinta: un número en rojo que
      // no se lee en voz alta no existe para quien navega por voz.
      text: count == 0 ? label : '$label ($count pendientes)',
    );
  }
}
