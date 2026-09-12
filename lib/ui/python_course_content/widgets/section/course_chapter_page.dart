import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/users_management/screens/teacher_module_editor.dart';

import 'chapter_section_screen.dart';
import 'section_theme.dart';
import 'section_widgets.dart';

/// Punto de entrada a un capítulo del curso.
///
/// Las pantallas de módulo solo dicen qué capítulo abrir; el contenido, la
/// navegación entre capítulos y el botón de edición docente se resuelven aquí
/// a partir del catálogo. Así el mismo capítulo se ve igual en tema claro y
/// oscuro, y añadir contenido no obliga a tocar ninguna pantalla.
class CourseChapterPage extends StatefulWidget {
  const CourseChapterPage({
    super.key,
    required this.moduleNumber,
    required this.sectionNumber,
    this.enableTeacherEditor = false,
  });

  final int moduleNumber;
  final int sectionNumber;

  /// Muestra el lápiz de edición a quien tenga rol docente.
  final bool enableTeacherEditor;

  @override
  State<CourseChapterPage> createState() => _CourseChapterPageState();
}

class _CourseChapterPageState extends State<CourseChapterPage> {
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableTeacherEditor) {
      _checkRole();
    }
  }

  Future<void> _checkRole() async {
    final role = await AuthStorage().getRole();
    if (!mounted) return;
    setState(() => _isTeacher = (role ?? '').toLowerCase() == 'docente');
  }

  void _goToChapter(int sectionNumber) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CourseChapterPage(
          moduleNumber: widget.moduleNumber,
          sectionNumber: sectionNumber,
          enableTeacherEditor: widget.enableTeacherEditor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = PythonCourseCatalog.moduleByNumber(widget.moduleNumber);
    final section = module?.sectionByNumber(widget.sectionNumber);

    if (module == null || section == null) {
      return _ChapterNotFound(
        moduleNumber: widget.moduleNumber,
        sectionNumber: widget.sectionNumber,
      );
    }

    final hasPrevious =
        module.sectionByNumber(widget.sectionNumber - 1) != null;
    final hasNext = module.sectionByNumber(widget.sectionNumber + 1) != null;

    return ChapterSectionScreen(
      module: module,
      section: section,
      onPreviousChapter: hasPrevious
          ? () => _goToChapter(widget.sectionNumber - 1)
          : null,
      onNextChapter: hasNext
          ? () => _goToChapter(widget.sectionNumber + 1)
          : null,
      trailingAction: _isTeacher ? _buildTeacherAction() : null,
    );
  }

  Widget _buildTeacherAction() {
    return Semantics(
      button: true,
      label: 'Editar el contenido de este capítulo',
      child: IconButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TeacherModuleEditor())),
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Editar capítulo',
        constraints: const BoxConstraints(
          minWidth: SectionMetrics.minTapTarget,
          minHeight: SectionMetrics.minTapTarget,
        ),
      ),
    );
  }
}

/// Se muestra si se pide un capítulo que no existe en el catálogo.
///
/// Preferimos una pantalla que explique qué pasó antes que una excepción o una
/// pantalla en blanco.
class _ChapterNotFound extends StatelessWidget {
  const _ChapterNotFound({
    required this.moduleNumber,
    required this.sectionNumber,
  });

  final int moduleNumber;
  final int sectionNumber;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: Colors.white,
        title: const Text('CODE4ALL'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SectionMetrics.maxContentWidth,
            ),
            child: SectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: 'Capítulo no disponible',
                    subtitle:
                        'No encontramos el capítulo $sectionNumber del módulo '
                        '$moduleNumber en el catálogo del curso.',
                    icon: Icons.search_off,
                    color: palette.warning,
                  ),
                  const SizedBox(height: 20),
                  SectionPrimaryButton(
                    label: 'Volver',
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
