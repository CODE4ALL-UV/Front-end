import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_quick_button.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';
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
    this.course,
  });

  /// El curso que se está editando. Nulo con el servidor de antes, que tenía
  /// un único curso para todos.
  final CourseInfo? course;

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

  /// Si la sección abierta al lado, en pantalla ancha, tiene cambios sin
  /// guardar.
  bool _sectionHasChanges = false;

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

  Future<void> _select(
    int moduleNumber,
    int sectionNumber, {
    required bool isWide,
  }) async {
    final sameSection =
        moduleNumber == _moduleNumber && sectionNumber == _sectionNumber;

    // En pantalla ancha elegir otra sección rehace el editor de al lado, y
    // lo escrito sin guardar se perdía sin aviso.
    if (isWide && !sameSection && _sectionHasChanges) {
      if (!await confirmDiscardChanges(context) || !mounted) return;
    }

    final appColorScheme = context.colorScheme;
    setState(() {
      _moduleNumber = moduleNumber;
      _sectionNumber = sectionNumber;
      if (!sameSection) _sectionHasChanges = false;
    });

    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: appColorScheme.surface,
            appBar: GlobalAppBarWidget(
              userName: widget.userName,
              onLogout: widget.onLogout,
              extraActions: const [AccessibilityQuickButton()],
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

  /// El código para que los estudiantes entren, a mano mientras se edita.
  Future<void> _showCode(CourseInfo course) async {
    final code = course.joinCode ?? '';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Código de ${course.title}'),
        content: Semantics(
          label: 'Código: ${code.split('').join(' ')}',
          excludeSemantics: true,
          child: SelectableText(
            code,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColorScheme = context.colorScheme;
    final course = widget.course;
    return Scaffold(
      backgroundColor: appColorScheme.surface,
      appBar: GlobalAppBarWidget(
        // Con varios cursos, el nombre del que se edita siempre a la vista:
        // editar el que no era es justo el error que hay que evitar.
        title: course?.title ?? 'CODE4ALL',
        userName: widget.userName,
        onLogout: widget.onLogout,
        extraActions: [
          if (course?.joinCode != null)
            IconButton(
              tooltip: 'Código para inscribirse',
              onPressed: () => _showCode(course!),
              color: appColorScheme.onPrimary,
              icon: const Icon(Icons.vpn_key_outlined),
            ),
          IconButton(
            tooltip: 'Volver a consultar los cambios guardados',
            onPressed: _content.isLoading ? null : _content.refresh,
            color: appColorScheme.onPrimary,
            icon: const Icon(Icons.refresh),
          ),
          const AccessibilityQuickButton(),
        ],
        // Sin estas pestañas las estadísticas y la lista de estudiantes
        // existían pero no había forma de llegar a ellas.
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
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
            _buildTemario(),
            const TeacherStatsScreen(),
            const TeacherStudentsScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildTemario() {
    final appColorScheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 900 px es donde caben cómodos el temario y la sección a la vez.
        final isWide = constraints.maxWidth >= 900;

        final tree = _ModuleTree(
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
            VerticalDivider(width: 1, color: appColorScheme.outline),
            Expanded(
              child: Column(
                children: [
                  if (_content.problem != null)
                    TeacherBanner(
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
                      // Solo se apunta: no cambia nada de lo que se ve aquí.
                      onUnsavedChanges: (changed) =>
                          _sectionHasChanges = changed,
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
    required this.content,
    required this.selectedModule,
    required this.selectedSection,
    required this.highlightSelection,
    required this.onSelect,
  });

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
          module: module,
          title: title,
          titleEdited: edited,
          startsExpanded: module.number == selectedModule,
          child: Column(
            children: [
              // Con lo editado encima: el título que puso el docente y
              // cuántas preguntas o videos le quedan de verdad.
              for (final (i, base) in module.sections.indexed)
                _SectionRow(
                  section: content.section(module.number, base.number) ?? base,
                  edited: content.isSectionEdited(base.id),
                  selected:
                      highlightSelection &&
                      module.number == selectedModule &&
                      base.number == selectedSection,
                  isFirst: i == 0,
                  isLast: i == module.sections.length - 1,
                  onTap: () => onSelect(module.number, base.number),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ModuleTile extends StatefulWidget {
  const _ModuleTile({
    required this.module,
    required this.title,
    required this.titleEdited,
    required this.startsExpanded,
    required this.child,
  });

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
    final appColorScheme = context.colorScheme;

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
                  minHeight: AppMetrics.minTapTarget,
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
                      color: appColorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _open
                            ? appColorScheme.secondary.withValues(alpha: 0.14)
                            : Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _moduleIcon(widget.module.number),
                        size: 17,
                        color: _open
                            ? appColorScheme.secondary
                            : appColorScheme.onSurfaceVariant,
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
                              color: appColorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: appColorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.titleEdited) EditedDot(label: 'Nombre cambiado'),
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

/// Lo que contiene una sección: cuánto de cada cosa y qué tipos de actividad.
///
/// Primero fue una fila de iconos sueltos, que no decían si había tres
/// preguntas o quince; después, una fila de distintivos que pesaba más que el
/// propio título. Ahora cada dato es un icono con su texto, sin cajas: el
/// icono y el color son los de la ruta del estudiante, así que el docente
/// reconoce de un vistazo lo mismo que encontrará su grupo.
class _SectionContents {
  _SectionContents(CourseSection section) {
    final reading = section.reading;
    if (reading != null) {
      final pages = reading.pages.length;
      counts.add((
        pages,
        pages == 1 ? 'página' : 'páginas',
        CourseActivityKind.lectura,
      ));
    }
    final videos = section.videos.length;
    if (videos > 0) {
      counts.add((
        videos,
        videos == 1 ? 'video' : 'videos',
        CourseActivityKind.video,
      ));
    }

    // Quiz y evaluación se juntan: al docente le importa cuántas preguntas
    // hay que responder en total, no en qué cajón están.
    final questions = section.quiz.length + section.finalEvaluation.length;
    if (questions > 0) {
      counts.add((
        questions,
        questions == 1 ? 'pregunta' : 'preguntas',
        CourseActivityKind.quiz,
      ));
    }

    if (section.capsule != null) {
      kinds.add(('Cápsula', CourseActivityKind.capsula));
    }
    if (section.example != null) {
      kinds.add(('Ejemplo', CourseActivityKind.ejemplo));
    }
    if (section.exercise != null && !section.exercise!.isEmpty) {
      kinds.add(('Ejercicio', CourseActivityKind.ejercicio));
    }
    if (section.hasLaboratory) {
      kinds.add(('Laboratorio', CourseActivityKind.laboratorio));
    }
  }

  /// «4 páginas», «1 video», «6 preguntas».
  final List<(int, String, CourseActivityKind)> counts = [];

  /// Cápsula, ejemplo, ejercicio y laboratorio, si los tiene.
  final List<(String, CourseActivityKind)> kinds = [];

  /// Por voz se dice lo mismo que se ve, en el mismo orden.
  String get spoken => [
    for (final (n, word, _) in counts) '$n $word',
    for (final (label, _) in kinds) label,
  ].join(', ');
}

/// Un dato de la sección: el icono de su actividad y su texto, sin caja.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.kind,
    required this.text,
    required this.textColor,
    this.number,
    this.numberColor,
  });

  final CourseActivityKind kind;
  final String text;
  final Color textColor;

  /// La cantidad, que va destacada delante del texto.
  final int? number;
  final Color? numberColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = SectionActivityLauncher.colorsFor(
      context,
      kind,
    ).foreground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(SectionActivityLauncher.iconFor(kind), size: 16, color: iconColor),
        const SizedBox(width: 5),
        // Flexible: con la letra al doble, en la columna de 300 px del
        // temario, un dato largo parte el renglón en vez de salirse.
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                if (number != null)
                  TextSpan(
                    text: '$number ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: numberColor,
                    ),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: TextStyle(fontSize: 12.5, height: 1.3, color: textColor),
          ),
        ),
      ],
    );
  }
}

/// El tramo de la línea de tiempo que toca a una sección.
///
/// La línea une los círculos de las secciones de un módulo: sube hasta el
/// círculo si hay una sección antes y baja desde él si hay otra después.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.center,
    required this.up,
    required this.down,
  });

  final Color color;

  /// A qué altura queda el centro del círculo.
  final double center;
  final bool up;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    if (up) canvas.drawLine(Offset(x, 0), Offset(x, center), paint);
    if (down) canvas.drawLine(Offset(x, center), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color ||
      old.center != center ||
      old.up != up ||
      old.down != down;
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.section,
    required this.edited,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final CourseSection section;
  final bool edited;
  final bool selected;

  /// Para saber si la línea de tiempo sigue por arriba o por abajo.
  final bool isFirst;
  final bool isLast;

  final VoidCallback onTap;

  /// Margen hasta la línea: así queda justo debajo del icono del módulo, y
  /// las secciones se ven colgando de él.
  static const double _railInset = 23;
  static const double _railWidth = 32;
  static const double _circle = 28;
  static const double _top = 12;

  @override
  Widget build(BuildContext context) {
    final contents = _SectionContents(section);
    final appColorScheme = context.colorScheme;
    // El secundario: se lee como texto en los seis temas.
    final accent = appColorScheme.secondary;
    final background = selected
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.09),
            appColorScheme.surface,
          )
        : appColorScheme.surface;
    final muted = AppContrast.readableOn(
      appColorScheme.onSurfaceVariant,
      background,
      AppContrast.text,
    );
    final accentText = AppContrast.readableOn(
      accent,
      background,
      AppContrast.text,
    );

    // El círculo de la sección: hueco, con el número en el color de acento;
    // lleno cuando es la que está abierta al lado. Una sección sin material
    // se queda en gris, como un hueco por llenar.
    final circle = Container(
      width: _circle,
      height: _circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? accent : background,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? accent
              : (section.isPlaceholder
                    ? appColorScheme.outlineVariant
                    : accent),
          width: 1.5,
        ),
      ),
      child: Text(
        '${section.number}',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected
              ? appColorScheme.onSecondary
              : (section.isPlaceholder ? muted : accentText),
        ),
      ),
    );

    final rail = SizedBox(
      width: _railWidth,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RailPainter(
                color: appColorScheme.outlineVariant,
                center: _top + _circle / 2,
                up: !isFirst,
                down: !isLast,
              ),
            ),
          ),
          Positioned(
            top: _top,
            left: (_railWidth - _circle) / 2,
            child: circle,
          ),
        ],
      ),
    );

    // Primero las cantidades, con su número destacado; debajo, los tipos de
    // actividad que tiene. Una sección sin material lo dice en vez de dejar
    // el hueco en blanco.
    final List<Widget> facts = section.isPlaceholder
        ? [
            Row(
              children: [
                Icon(Icons.hourglass_empty, size: 16, color: muted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Sin contenido',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ]
        : [
            if (contents.counts.isNotEmpty)
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final (n, word, kind) in contents.counts)
                    _Fact(
                      kind: kind,
                      number: n,
                      numberColor: appColorScheme.onSurface,
                      text: word,
                      textColor: muted,
                    ),
                ],
              ),
            if (contents.counts.isNotEmpty && contents.kinds.isNotEmpty)
              const SizedBox(height: 6),
            if (contents.kinds.isNotEmpty)
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final (label, kind) in contents.kinds)
                    _Fact(kind: kind, text: label, textColor: muted),
                ],
              ),
          ];

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.3,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? accentText : appColorScheme.onSurface,
            ),
          ),
        ),
        if (edited) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, size: 14, color: accentText),
                const SizedBox(width: 3),
                Text(
                  'Editada',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accentText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label:
          'Sección ${section.number}, ${section.title}. '
          '${section.isPlaceholder ? "Sin contenido todavía" : contents.spoken}.'
          '${edited ? " Con cambios tuyos." : ""}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              // IntrinsicHeight: la línea de tiempo mide lo mismo que la fila,
              // también cuando el título ocupa dos renglones.
              child: IntrinsicHeight(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppMetrics.minTapTarget + 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(width: _railInset),
                      rail,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: _top + 4,
                            bottom: _top + 4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              title,
                              const SizedBox(height: 8),
                              ...facts,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: _top + 4,
                          left: 4,
                          right: 8,
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: selected ? accentText : muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
