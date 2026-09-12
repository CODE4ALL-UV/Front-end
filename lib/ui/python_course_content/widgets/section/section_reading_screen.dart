import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state.dart';

import 'section_activity_scaffold.dart';
import 'section_theme.dart';
import 'section_widgets.dart';

/// Lectura de una sección, dividida en páginas navegables.
class SectionReadingScreen extends StatefulWidget {
  const SectionReadingScreen({
    super.key,
    required this.module,
    required this.section,
  });

  final CourseModule module;
  final CourseSection section;

  @override
  State<SectionReadingScreen> createState() => _SectionReadingScreenState();
}

class _SectionReadingScreenState extends State<SectionReadingScreen> {
  int _pageIndex = 0;
  bool _finished = false;

  SectionReading get _reading => widget.section.reading!;
  List<ReadingPage> get _pages => _reading.pages;
  ReadingPage get _currentPage => _pages[_pageIndex];

  bool get _isLastPage => _pageIndex == _pages.length - 1;

  void _goTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= _pages.length) return;

    accessibilityReadingState.stop();
    setState(() => _pageIndex = nextIndex);

    announceForAccessibility(
      context,
      'Página ${nextIndex + 1} de ${_pages.length}. '
      '${_pages[nextIndex].title}',
    );
  }

  Future<void> _finish() async {
    await CourseProgressStore.instance.markCompleted(
      widget.section.id,
      CourseActivityKind.lectura,
    );

    if (!mounted) return;

    setState(() => _finished = true);
    announceForAccessibility(
      context,
      'Lectura completada. Has terminado las ${_pages.length} páginas de '
      '${widget.section.title}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionActivityScaffold(
      moduleLabel: widget.module.label,
      sectionTitle: widget.section.displayTitle,
      activityLabel: 'Lectura',
      activityIcon: Icons.menu_book_outlined,
      spokenText: _currentPage.spokenText,
      progress: (_pageIndex + 1) / _pages.length,
      progressLabel: 'Página ${_pageIndex + 1} de ${_pages.length}',
      bottomBar: _buildBottomBar(palette),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          key: ValueKey<int>(_pageIndex),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pageIndex == 0) ...[
              SectionCard(
                background: palette.accentSoft,
                borderColor: palette.accent.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeading(
                      title: _reading.title,
                      subtitle: _reading.intro,
                      icon: Icons.auto_stories_outlined,
                      color: palette.accent,
                    ),
                    if (widget.section.objectives.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Al terminar esta lectura podrás:',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SectionList(
                        items: widget.section.objectives,
                        numbered: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: SectionMetrics.sectionGap),
            ],
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: _currentPage.title,
                    subtitle: _currentPage.summary,
                    icon: Icons.article_outlined,
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < _currentPage.blocks.length; i++) ...[
                    if (i > 0) const SizedBox(height: SectionMetrics.gap + 6),
                    _ReadingBlockView(block: _currentPage.blocks[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: SectionMetrics.sectionGap),
            _PageDots(count: _pages.length, currentIndex: _pageIndex),
            if (_finished) ...[
              const SizedBox(height: SectionMetrics.sectionGap),
              SectionCallout(
                title: 'Lectura completada',
                body:
                    'Has terminado las ${_pages.length} páginas de '
                    '"${widget.section.title}". Continúa con la cápsula de '
                    'conocimiento o con el ejemplo para afianzar lo leído.',
                tone: SectionTone.success,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(SectionPalette palette) {
    if (_finished) {
      return SectionPrimaryButton(
        label: 'Volver a la ruta de actividades',
        icon: Icons.check_circle_outline,
        tone: SectionTone.success,
        semanticHint: 'Regresa al listado de actividades de la sección',
        onPressed: () => Navigator.of(context).pop(true),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SectionSecondaryButton(
            label: 'Anterior',
            icon: Icons.arrow_back,
            semanticHint: _pageIndex == 0
                ? 'Ya estás en la primera página'
                : 'Ir a la página $_pageIndex',
            onPressed: _pageIndex == 0 ? null : () => _goTo(_pageIndex - 1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SectionPrimaryButton(
            label: _isLastPage ? 'Finalizar' : 'Siguiente',
            icon: _isLastPage ? Icons.check : Icons.arrow_forward,
            semanticHint: _isLastPage
                ? 'Marca la lectura como completada'
                : 'Ir a la página ${_pageIndex + 2} de ${_pages.length}',
            onPressed: _isLastPage ? _finish : () => _goTo(_pageIndex + 1),
          ),
        ),
      ],
    );
  }
}

/// Dibuja cada tipo de bloque de lectura.
class _ReadingBlockView extends StatelessWidget {
  const _ReadingBlockView({required this.block});

  final ReadingBlock block;

  SectionTone get _tone => switch (block.tone) {
    CalloutTone.info => SectionTone.info,
    CalloutTone.success => SectionTone.success,
    CalloutTone.warning => SectionTone.warning,
    CalloutTone.danger => SectionTone.danger,
  };

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    if (block.kind == ReadingBlockKind.callout) {
      return SectionCallout(title: block.title, body: block.body, tone: _tone);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text(
              block.title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (block.body.isNotEmpty) ...[
          SectionParagraph(block.body),
          if (block.items.isNotEmpty || block.code != null)
            const SizedBox(height: 12),
        ],
        if (block.items.isNotEmpty)
          SectionList(
            items: block.items,
            numbered: block.kind == ReadingBlockKind.steps,
          ),
        if (block.code != null)
          SectionCodeBlock(code: block.code!, caption: block.codeCaption),
      ],
    );
  }
}

/// Indicador de páginas. Se excluye de la semántica porque la barra de avance
/// ya comunica lo mismo, y repetirlo en voz alta solo estorba.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 22 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: isActive ? palette.accent : palette.border,
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
            ),
          );
        }),
      ),
    );
  }
}
