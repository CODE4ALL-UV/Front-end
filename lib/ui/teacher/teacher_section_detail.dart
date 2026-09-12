import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import 'course_section_edits.dart';
import 'editors/capsule_editor_screen.dart';
import 'editors/example_editor_screen.dart';
import 'editors/exercise_editor_screen.dart';
import 'editors/quiz_editor_screen.dart';
import 'editors/reading_editor_screen.dart';
import 'editors/videos_editor_screen.dart';
import 'teacher_widgets.dart';

/// Una sección vista por el docente, con sus actividades listas para editar.
///
/// Editar una sección entera en un solo formulario serían cientos de campos.
/// Aquí cada actividad es una tarjeta que dice de un vistazo qué contiene, y
/// se abre en su propio editor. Lo que se escribe **no sale de esta pantalla**
/// hasta pulsar guardar: hasta entonces el estudiante sigue viendo lo de antes.
class TeacherSectionDetail extends StatefulWidget {
  const TeacherSectionDetail({
    super.key,
    required this.moduleNumber,
    required this.sectionNumber,
  });

  final int moduleNumber;
  final int sectionNumber;

  @override
  State<TeacherSectionDetail> createState() => _TeacherSectionDetailState();
}

class _TeacherSectionDetailState extends State<TeacherSectionDetail> {
  final CourseContentStore _content = CourseContentStore.instance;

  late CourseSection _draft;
  late CourseSection _saved;

  late final TextEditingController _title;
  late final TextEditingController _shortTitle;
  late final TextEditingController _summary;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final section =
        _content.section(widget.moduleNumber, widget.sectionNumber) ??
        PythonCourseCatalog.section(widget.moduleNumber, widget.sectionNumber)!;

    _saved = section;
    _draft = section;

    _title = TextEditingController(text: section.title);
    _shortTitle = TextEditingController(text: section.shortTitle ?? '');
    _summary = TextEditingController(text: section.summary);
  }

  @override
  void dispose() {
    _title.dispose();
    _shortTitle.dispose();
    _summary.dispose();
    super.dispose();
  }

  /// Recoge lo escrito en los campos sueltos al borrador.
  CourseSection get _current {
    final short = _shortTitle.text.trim();
    return _draft.copyWith(
      title: _title.text.trim(),
      shortTitle: short.isEmpty ? null : short,
      summary: _summary.text.trim(),
    );
  }

  bool get _hasChanges {
    final now = _current;
    return now.title != _saved.title ||
        now.shortTitle != _saved.shortTitle ||
        now.summary != _saved.summary ||
        !identical(now.reading, _saved.reading) ||
        !identical(now.capsule, _saved.capsule) ||
        !identical(now.example, _saved.example) ||
        !identical(now.exercise, _saved.exercise) ||
        !identical(now.quiz, _saved.quiz) ||
        !identical(now.finalEvaluation, _saved.finalEvaluation) ||
        !identical(now.videos, _saved.videos);
  }

  void _update(CourseSection next) {
    setState(() {
      _draft = next;
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final section = _current;
    try {
      await _content.saveSection(section);
      if (!mounted) return;

      setState(() {
        _saved = section;
        _draft = section;
        _saving = false;
      });

      announceForAccessibility(
        context,
        'Sección guardada. Los estudiantes ya la ven así.',
      );
      _toast('Guardado. Los estudiantes ya lo ven.', ok: true);
    } on CourseEditException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
      announceForAccessibility(context, e.message);
    }
  }

  Future<void> _revert() async {
    final original = PythonCourseCatalog.section(
      widget.moduleNumber,
      widget.sectionNumber,
    )!;

    final sure = await confirmDelete(
      context,
      what: 'tus cambios en esta sección',
      detail:
          'La sección volverá al contenido original del curso. No se borra '
          'nada del temario: solo se descarta lo que editaste.',
    );
    if (!sure || !mounted) return;

    setState(() => _saving = true);
    try {
      await _content.revertSection(original.id);
      if (!mounted) return;

      setState(() {
        _saved = original;
        _draft = original;
        _title.text = original.title;
        _shortTitle.text = original.shortTitle ?? '';
        _summary.text = original.summary;
        _saving = false;
      });
      _toast('Sección devuelta a su versión original.', ok: true);
    } on CourseEditException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  void _toast(String message, {bool ok = false}) {
    final palette = SectionPalette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? palette.success : palette.danger,
      ),
    );
  }

  /// Enseña la sección tal y como la verá el estudiante, con lo editado.
  void _previewAsStudent() {
    final module = PythonCourseCatalog.moduleByNumber(widget.moduleNumber)!;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChapterSectionScreen(
          module: CourseModule(
            number: module.number,
            title: _content.moduleTitle(module.number, module.title),
            sections: module.sections,
          ),
          section: _current,
        ),
      ),
    );
  }

  Future<T?> _open<T>(Widget screen) => Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final section = _current;
    final edited = _content.isSectionEdited(section.id);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: SectionMetrics.pagePadding(constraints.maxWidth),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SectionMetrics.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(palette, edited),
                        const SizedBox(height: SectionMetrics.gap),
                        _identityCard(palette),
                        const SizedBox(height: SectionMetrics.sectionGap),
                        Text(
                          'Actividades',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SectionMetrics.gap),
                        ..._activityCards(palette, section),
                        if (_error != null) ...[
                          const SizedBox(height: SectionMetrics.gap),
                          TeacherBanner(
                            palette: palette,
                            icon: Icons.error_outline,
                            text: _error!,
                            tone: palette.danger,
                          ),
                        ],
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _saveBar(palette, edited),
      ],
    );
  }

  Widget _header(SectionPalette palette, bool edited) {
    final where = Text(
      'Módulo ${widget.moduleNumber} · Sección ${widget.sectionNumber}',
      style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
    );

    final badge = edited
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
            ),
            child: Text(
              'Editada',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          )
        : const SizedBox.shrink();

    final preview = TextButton.icon(
      onPressed: _previewAsStudent,
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        minimumSize: const Size(0, SectionMetrics.minTapTarget),
      ),
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('Ver como estudiante'),
    );

    // El botón y la etiqueta no se pueden encoger. En pantalla estrecha, o con
    // el texto agrandado, no caben al lado del título y hay que bajarlos.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: where),
                  badge,
                ],
              ),
              Align(alignment: Alignment.centerLeft, child: preview),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: where),
            badge,
            const SizedBox(width: 8),
            preview,
          ],
        );
      },
    );
  }

  Widget _identityCard(SectionPalette palette) {
    return TeacherCard(
      palette: palette,
      child: Column(
        children: [
          TeacherField(
            palette: palette,
            label: 'Título de la sección',
            controller: _title,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: SectionMetrics.gap),
          TeacherField(
            palette: palette,
            label: 'Título corto',
            controller: _shortTitle,
            hint: 'Se deja vacío para usar el título completo',
            helper:
                'Es el que aparece en la tarjeta del mapa. Un título largo se '
                'encoge hasta volverse ilegible.',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: SectionMetrics.gap),
          TeacherField(
            palette: palette,
            label: 'Descripción',
            controller: _summary,
            maxLines: 3,
            helper: 'Lo que el estudiante lee antes de entrar.',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  List<Widget> _activityCards(SectionPalette palette, CourseSection section) {
    return [
      _ActivityCard(
        palette: palette,
        icon: Icons.menu_book,
        color: palette.accent,
        title: 'Lectura',
        detail: section.reading == null
            ? 'Sin lectura'
            : '${section.reading!.pages.length} páginas · '
                  '${section.reading!.pages.fold<int>(0, (n, p) => n + p.blocks.length)} bloques',
        empty: section.reading == null,
        onTap: () async {
          final result = await _open<SectionReading?>(
            ReadingEditorScreen(reading: section.reading, section: section),
          );
          if (result != null) _update(_draft.copyWith(reading: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.lightbulb_outline,
        color: palette.warning,
        title: 'Cápsula de conocimiento',
        detail: section.capsule == null
            ? 'Sin cápsula'
            : '${section.capsule!.tips.length} consejos',
        empty: section.capsule == null,
        onTap: () async {
          final result = await _open<KnowledgeCapsule?>(
            CapsuleEditorScreen(capsule: section.capsule),
          );
          if (result != null) _update(_draft.copyWith(capsule: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.play_circle_outline,
        color: palette.danger,
        title: 'Videos',
        detail: section.videos.isEmpty
            ? 'Sin videos'
            : '${section.videos.length} '
                  '${section.videos.length == 1 ? "video" : "videos"}',
        empty: section.videos.isEmpty,
        onTap: () async {
          final result = await _open<List<SectionVideo>?>(
            VideosEditorScreen(videos: section.videos),
          );
          if (result != null) _update(_draft.copyWith(videos: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.quiz_outlined,
        color: palette.success,
        title: 'Quiz',
        detail: section.quiz.isEmpty
            ? 'Sin preguntas'
            : '${section.quiz.length} '
                  '${section.quiz.length == 1 ? "pregunta" : "preguntas"}',
        empty: section.quiz.isEmpty,
        onTap: () async {
          final result = await _open<List<QuizQuestion>?>(
            QuizEditorScreen(
              questions: section.quiz,
              title: 'Quiz de la sección',
            ),
          );
          if (result != null) _update(_draft.copyWith(quiz: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.fact_check_outlined,
        color: palette.success,
        title: 'Evaluación final',
        detail: section.finalEvaluation.isEmpty
            ? 'Sin preguntas'
            : '${section.finalEvaluation.length} preguntas',
        empty: section.finalEvaluation.isEmpty,
        onTap: () async {
          final result = await _open<List<QuizQuestion>?>(
            QuizEditorScreen(
              questions: section.finalEvaluation,
              title: 'Evaluación final',
            ),
          );
          if (result != null) _update(_draft.copyWith(finalEvaluation: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.code,
        color: palette.accent,
        title: 'Ejemplo comentado',
        detail: section.example == null
            ? 'Sin ejemplo'
            : '${section.example!.steps.length} pasos explicados',
        empty: section.example == null,
        onTap: () async {
          final result = await _open<CodeExample?>(
            ExampleEditorScreen(example: section.example),
          );
          if (result != null) _update(_draft.copyWith(example: result));
        },
      ),
      _ActivityCard(
        palette: palette,
        icon: Icons.edit_note,
        color: palette.warning,
        title: 'Ejercicio',
        detail: section.exercise == null || section.exercise!.isEmpty
            ? 'Sin ejercicio'
            : '${section.exercise!.pairs.length} parejas · '
                  '${section.exercise!.questions.length} preguntas',
        empty: section.exercise == null || section.exercise!.isEmpty,
        onTap: () async {
          final result = await _open<SectionExercise?>(
            ExerciseEditorScreen(exercise: section.exercise),
          );
          if (result != null) _update(_draft.copyWith(exercise: result));
        },
      ),
      _LaboratoryCard(
        palette: palette,
        enabled: section.hasLaboratory,
        onChanged: (value) => _update(_draft.copyWith(hasLaboratory: value)),
      ),
    ];
  }

  Widget _saveBar(SectionPalette palette, bool edited) {
    final changed = _hasChanges;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final status = Semantics(
              liveRegion: true,
              child: Text(
                _saving
                    ? 'Guardando…'
                    : changed
                    ? 'Tienes cambios sin guardar'
                    : edited
                    ? 'Guardado. Los estudiantes lo ven así.'
                    : 'Sin cambios',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: changed ? FontWeight.w700 : FontWeight.w400,
                  color: changed ? palette.warning : palette.textSecondary,
                ),
              ),
            );

            final revert = (edited && !changed)
                ? TextButton(
                    onPressed: _saving ? null : _revert,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.danger,
                      minimumSize: const Size(0, SectionMetrics.minTapTarget),
                    ),
                    child: const Text('Volver al original'),
                  )
                : const SizedBox.shrink();

            final save = FilledButton.icon(
              onPressed: (_saving || !changed) ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                minimumSize: const Size(0, SectionMetrics.minTapTarget),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar'),
            );

            // Con el texto agrandado los botones no caben junto al mensaje.
            // Guardar nunca puede quedar fuera de la pantalla: es lo único que
            // impide perder lo escrito.
            if (constraints.maxWidth < 420) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  status,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: revert),
                      const SizedBox(width: 8),
                      Expanded(child: save),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: status),
                revert,
                const SizedBox(width: 8),
                save,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Una actividad de la sección, con lo que contiene de un vistazo.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.empty,
    required this.onTap,
  });

  final SectionPalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool empty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $detail. Toca para editar.',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: SectionMetrics.minTapTarget,
                ),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(
                    SectionMetrics.cardRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: empty ? palette.textSecondary : color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            detail,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.textSecondary),
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

/// El laboratorio no tiene contenido que editar: se enciende o se apaga.
class _LaboratoryCard extends StatelessWidget {
  const _LaboratoryCard({
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final SectionPalette palette;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // El fondo va en el Material y no en la decoración: si no, el interruptor
    // pinta su pulsación por debajo y no se ve.
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
        ),
        child: SwitchListTile(
          value: enabled,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          activeThumbColor: palette.accent,
          title: Text(
            'Laboratorio',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          subtitle: Text(
            enabled
                ? 'El estudiante puede escribir y ejecutar código'
                : 'Esta sección no ofrece laboratorio',
            style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
          ),
        ),
      ),
    );
  }
}
