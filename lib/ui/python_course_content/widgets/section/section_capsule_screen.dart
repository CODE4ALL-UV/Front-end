import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

import 'section_activity_scaffold.dart';
import 'section_theme.dart';
import 'section_widgets.dart';

/// Cápsula de conocimiento: el consejo breve que cierra cada sección.
class SectionCapsuleScreen extends StatelessWidget {
  const SectionCapsuleScreen({
    super.key,
    required this.module,
    required this.section,
  });

  final CourseModule module;
  final CourseSection section;

  KnowledgeCapsule get _capsule => section.capsule!;

  String get _spokenText {
    final buffer = StringBuffer()
      ..writeln(_capsule.headline)
      ..writeln(_capsule.intro);
    for (final tip in _capsule.tips) {
      buffer
        ..writeln(tip.title)
        ..writeln(tip.body);
    }
    if (_capsule.hasCodeComparison) {
      buffer
        ..writeln('Así no: ${_capsule.badCodeCaption ?? ''}')
        ..writeln('Así sí: ${_capsule.goodCodeCaption ?? ''}');
    }
    buffer.writeln(_capsule.closing);
    return buffer.toString();
  }

  Future<void> _finish(BuildContext context) async {
    await CourseProgressStore.instance.markCompleted(
      section.id,
      CourseActivityKind.capsula,
    );

    if (!context.mounted) return;

    announceForAccessibility(context, 'Cápsula de conocimiento completada.');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionActivityScaffold(
      moduleLabel: module.label,
      sectionTitle: section.displayTitle,
      activityLabel: 'Cápsula de conocimiento',
      activityIcon: Icons.tips_and_updates_outlined,
      spokenText: _spokenText,
      bottomBar: SectionPrimaryButton(
        label: 'Entendido, marcar como vista',
        icon: Icons.check_circle_outline,
        tone: SectionTone.success,
        semanticHint: 'Marca la cápsula como completada y vuelve a la ruta',
        onPressed: () => _finish(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            background: palette.accentSoft,
            borderColor: palette.accent.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionStatusChip(
                  label: _capsule.title,
                  icon: Icons.auto_awesome,
                  tone: SectionTone.info,
                ),
                const SizedBox(height: 14),
                SectionHeading(
                  title: _capsule.headline,
                  subtitle: _capsule.intro,
                  color: palette.accent,
                ),
              ],
            ),
          ),
          if (_capsule.hasCodeComparison) ...[
            const SizedBox(height: SectionMetrics.sectionGap),
            _CodeComparison(capsule: _capsule),
          ],
          const SizedBox(height: SectionMetrics.sectionGap),
          for (var i = 0; i < _capsule.tips.length; i++) ...[
            if (i > 0) const SizedBox(height: SectionMetrics.gap),
            _TipCard(index: i + 1, tip: _capsule.tips[i]),
          ],
          const SizedBox(height: SectionMetrics.sectionGap),
          SectionCallout(
            title: 'Para recordar',
            body: _capsule.closing,
            tone: SectionTone.success,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.index, required this.tip});

  final int index;
  final CapsuleTip tip;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: palette.accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    tip.title,
                    style: TextStyle(
                      fontSize: 16.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SectionParagraph(tip.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Comparación "así no / así sí".
///
/// El icono y la etiqueta dicen cuál es cuál: el color solo acompaña.
class _CodeComparison extends StatelessWidget {
  const _CodeComparison({required this.capsule});

  final KnowledgeCapsule capsule;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          borderColor: palette.danger.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionStatusChip(
                label: 'Así no',
                icon: Icons.thumb_down_alt_outlined,
                tone: SectionTone.danger,
              ),
              const SizedBox(height: 12),
              SectionCodeBlock(
                code: capsule.badCode!,
                caption: capsule.badCodeCaption,
              ),
            ],
          ),
        ),
        const SizedBox(height: SectionMetrics.gap),
        SectionCard(
          borderColor: palette.success.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionStatusChip(
                label: 'Así sí',
                icon: Icons.thumb_up_alt_outlined,
                tone: SectionTone.success,
              ),
              const SizedBox(height: 12),
              SectionCodeBlock(
                code: capsule.goodCode!,
                caption: capsule.goodCodeCaption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
