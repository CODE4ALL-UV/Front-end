import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'teacher_section_detail.dart';
import 'teacher_stats_screen.dart';
import 'teacher_students_screen.dart';
import 'teacher_widgets.dart';

/// El curso entero, para que el docente lo edite.
///
/// A diferencia de la ruta del estudiante —un mapa de círculos que premia
/// avanzar— aquí manda ver el temario completo de un vistazo y poder saltar a
/// cualquier sección sin recorrer el camino. Por eso es un árbol y no un mapa.
///
/// En pantalla ancha el temario queda fijo a la izquierda y la sección se abre
/// al lado, que es como se edita de verdad: mirando el conjunto mientras se
/// toca una parte. En pantalla estrecha se navega de uno en uno.
class TeacherCourseScreen extends StatefulWidget {
  const TeacherCourseScreen({
    super.key,
    this.userName = 'Docente',
    this.onLogout,
  });

  /// Nombre de quien ha entrado, para el menú de la esquina.
  final String userName;

  /// Cerrar sesión. Viene de fuera porque es la aplicación quien sabe a dónde
  /// volver.
  final VoidCallback? onLogout;

  @override
  State<TeacherCourseScreen> createState() => _TeacherCourseScreenState();
}

class _TeacherCourseScreenState extends State<TeacherCourseScreen>
    with SingleTickerProviderStateMixin {
  final CourseContentStore _content = CourseContentStore.instance;

  late final TabController _tabs = TabController(length: 3, vsync: this);

  int _moduleNumber = 1;
  int _sectionNumber = 1;

  @override
  void initState() {
    super.initState();
    _content.addListener(_onChanged);
    _content.refresh();
  }

  @override
  void dispose() {
    _content.removeListener(_onChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _select(int moduleNumber, int sectionNumber, {required bool isWide}) {
    setState(() {
      _moduleNumber = moduleNumber;
      _sectionNumber = sectionNumber;
    });

    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: SectionPalette.of(context).background,
            appBar: AppBar(
              backgroundColor: SectionPalette.of(context).appBar,
              foregroundColor: SectionPalette.of(context).onAccent,
              title: const Text('Editar sección'),
            ),
            body: TeacherSectionDetail(
              moduleNumber: moduleNumber,
              sectionNumber: sectionNumber,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        // La misma barra que ve el estudiante: mismo logo, mismo nombre y el
        // mismo menú de cuenta. Cambiar de rol no debería parecer cambiar de
        // aplicación.
        backgroundColor: VisualThemeController.resolveIsDark(context)
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE53935),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset('assets/images/logoUV_Gris1.png'),
        ),
        title: const Text(
          'CODE4ALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Volver a consultar los cambios guardados',
            onPressed: _content.isLoading ? null : _content.refresh,
            color: Colors.white,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: UserProfileMenu(
              userName: widget.userName,
              onLogout: widget.onLogout,
              showName: true,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Temario'),
            Tab(icon: Icon(Icons.insights), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.groups_outlined), text: 'Estudiantes'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildTemario(palette),
            const TeacherStatsScreen(),
            const TeacherStudentsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemario(SectionPalette palette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 900 px es donde caben cómodos el temario y la sección a la vez.
        final isWide = constraints.maxWidth >= 900;

        final tree = _ModuleTree(
          palette: palette,
          content: _content,
          selectedModule: _moduleNumber,
          selectedSection: _sectionNumber,
          highlightSelection: isWide,
          onSelect: (m, s) => _select(m, s, isWide: isWide),
        );

        if (!isWide) {
          return Column(
            children: [
              if (_content.problem != null)
                TeacherBanner(
                  palette: palette,
                  icon: Icons.cloud_off,
                  text:
                      'No se pudo consultar el servidor. Estás viendo el '
                      'contenido original; tus cambios guardados podrían '
                      'no aparecer.',
                ),
              Expanded(child: tree),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 300, child: tree),
            VerticalDivider(width: 1, color: palette.border),
            Expanded(
              child: Column(
                children: [
                  if (_content.problem != null)
                    TeacherBanner(
                      palette: palette,
                      icon: Icons.cloud_off,
                      text:
                          'No se pudo consultar el servidor. Estás viendo '
                          'el contenido original.',
                    ),
                  Expanded(
                    child: TeacherSectionDetail(
                      // La clave hace que al cambiar de sección el editor
                      // se rehaga: si no, el texto de la anterior se
                      // quedaría en los campos.
                      key: ValueKey('$_moduleNumber-$_sectionNumber'),
                      moduleNumber: _moduleNumber,
                      sectionNumber: _sectionNumber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Un icono por módulo, para reconocerlo de un vistazo.
///
/// No sustituye al nombre: acompaña. Un icono solo, sin texto, sería
/// indescifrable para quien no conoce el curso.
IconData _moduleIcon(int number) => switch (number) {
  1 => Icons.flag_outlined,
  2 => Icons.abc,
  3 => Icons.alt_route,
  4 => Icons.widgets_outlined,
  5 => Icons.psychology_outlined,
  _ => Icons.rocket_launch_outlined,
};

/// El temario: módulos que se despliegan en secciones.
class _ModuleTree extends StatelessWidget {
  const _ModuleTree({
    required this.palette,
    required this.content,
    required this.selectedModule,
    required this.selectedSection,
    required this.highlightSelection,
    required this.onSelect,
  });

  final SectionPalette palette;
  final CourseContentStore content;
  final int selectedModule;
  final int selectedSection;

  /// En pantalla estrecha no se resalta nada: al tocar se abre otra pantalla,
  /// así que marcar una fila como «seleccionada» solo confundiría.
  final bool highlightSelection;

  final void Function(int moduleNumber, int sectionNumber) onSelect;

  @override
  Widget build(BuildContext context) {
    final modules = PythonCourseCatalog.modules;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        final title = content.moduleTitle(module.number, module.title);
        final edited = content.isModuleEdited(module.number);

        return _ModuleTile(
          palette: palette,
          module: module,
          title: title,
          titleEdited: edited,
          startsExpanded: module.number == selectedModule,
          child: Column(
            children: [
              for (final section in module.sections)
                _SectionRow(
                  palette: palette,
                  section: section,
                  edited: content.isSectionEdited(section.id),
                  selected:
                      highlightSelection &&
                      module.number == selectedModule &&
                      section.number == selectedSection,
                  onTap: () => onSelect(module.number, section.number),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.palette,
    required this.module,
    required this.title,
    required this.titleEdited,
    required this.startsExpanded,
    required this.child,
  });

  final SectionPalette palette;
  final CourseModule module;
  final String title;
  final bool titleEdited;
  final bool startsExpanded;
  final Widget child;

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  late bool _open = widget.startsExpanded;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label:
              'Módulo ${widget.module.number}, ${widget.title}, '
              '${widget.module.sections.length} secciones',
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: SectionMetrics.minTapTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _open ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _open ? palette.accentSoft : palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _moduleIcon(widget.module.number),
                        size: 17,
                        color: _open ? palette.accent : palette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Módulo ${widget.module.number}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: palette.textSecondary,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.titleEdited)
                      EditedDot(palette: palette, label: 'Nombre cambiado'),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) widget.child,
      ],
    );
  }
}

/// Lo que contiene una sección, en distintivos legibles.
///
/// Antes esto era una fila de iconos pequeños. Un icono suelto no dice si hay
/// tres preguntas o quince, y siete seguidos se vuelven indescifrables. Un
/// distintivo con su número se entiende de un vistazo y además se puede leer
/// en voz alta.
List<(String, IconData)> _sectionBadges(CourseSection section) {
  final badges = <(String, IconData)>[];

  final reading = section.reading;
  if (reading != null) {
    final pages = reading.pages.length;
    badges.add((
      '$pages ${pages == 1 ? "página" : "páginas"}',
      Icons.menu_book,
    ));
  }
  if (section.videos.isNotEmpty) {
    badges.add((
      '${section.videos.length} '
          '${section.videos.length == 1 ? "video" : "videos"}',
      Icons.play_circle_outline,
    ));
  }

  // Quiz y evaluación se juntan: al docente le importa cuántas preguntas hay
  // que responder en total, no en qué cajón están.
  final questions = section.quiz.length + section.finalEvaluation.length;
  if (questions > 0) {
    badges.add((
      '$questions ${questions == 1 ? "pregunta" : "preguntas"}',
      Icons.quiz_outlined,
    ));
  }

  if (section.capsule != null) badges.add(('Cápsula', Icons.lightbulb_outline));
  if (section.example != null) badges.add(('Ejemplo', Icons.code));
  if (section.exercise != null && !section.exercise!.isEmpty) {
    badges.add(('Ejercicio', Icons.edit_note));
  }
  if (section.hasLaboratory) badges.add(('Laboratorio', Icons.terminal));

  return badges;
}

/// Un distintivo suelto: icono pequeño y su texto.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.palette,
    required this.label,
    required this.icon,
  });

  final SectionPalette palette;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.palette,
    required this.section,
    required this.edited,
    required this.selected,
    required this.onTap,
  });

  final SectionPalette palette;
  final CourseSection section;
  final bool edited;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badges = _sectionBadges(section);

    return Semantics(
      button: true,
      selected: selected,
      // Por voz se dice lo mismo que se ve, en palabras: los distintivos de
      // la tarjeta leídos uno detrás de otro.
      label:
          'Sección ${section.number}, ${section.title}. '
          '${section.isPlaceholder ? "Sin contenido todavía." : badges.map((b) => b.$1).join(", ")}.'
          '${edited ? " Con cambios tuyos." : ""}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Material(
            color: selected ? palette.accentSoft : palette.surface,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: SectionMetrics.minTapTarget,
                ),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    SectionMetrics.cardRadius,
                  ),
                  border: Border.all(
                    color: selected ? palette.accent : palette.border,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // El número, no un icono: aquí lo que hace falta es
                        // saber en qué orden van.
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? palette.accent
                                : palette.surfaceAlt,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${section.number}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? palette.onAccent
                                  : palette.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.25,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected
                                  ? palette.accent
                                  : palette.textPrimary,
                            ),
                          ),
                        ),
                        if (edited)
                          EditedDot(palette: palette, label: 'Editada'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (section.isPlaceholder)
                      _Badge(
                        palette: palette,
                        label: 'Sin contenido',
                        icon: Icons.hourglass_empty,
                      )
                    else
                      // Los distintivos dicen qué tiene la sección y con
                      // cuánto, sin abrirla: si le falta el video, o si el
                      // quiz solo tiene dos preguntas, se ve desde aquí.
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final badge in badges)
                            _Badge(
                              palette: palette,
                              label: badge.$1,
                              icon: badge.$2,
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
