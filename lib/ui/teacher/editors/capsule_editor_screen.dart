import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';

/// La cápsula de conocimiento: los consejos que resumen lo esencial.
///
/// Permite además enseñar el mismo código mal y bien escrito, que es la forma
/// más rápida de que se entienda una buena práctica.
class CapsuleEditorScreen extends StatefulWidget {
  const CapsuleEditorScreen({super.key, required this.capsule});

  final KnowledgeCapsule? capsule;

  @override
  State<CapsuleEditorScreen> createState() => _CapsuleEditorScreenState();
}

class _CapsuleEditorScreenState extends State<CapsuleEditorScreen> {
  KnowledgeCapsule? _capsule;

  late final TextEditingController _title;
  late final TextEditingController _headline;
  late final TextEditingController _intro;
  late final TextEditingController _closing;
  late final TextEditingController _badCode;
  late final TextEditingController _goodCode;
  late final TextEditingController _badCaption;
  late final TextEditingController _goodCaption;

  late List<_TipFields> _tips;

  @override
  void initState() {
    super.initState();
    final capsule = widget.capsule;
    _capsule = capsule;

    _title = TextEditingController(text: capsule?.title ?? '');
    _headline = TextEditingController(text: capsule?.headline ?? '');
    _intro = TextEditingController(text: capsule?.intro ?? '');
    _closing = TextEditingController(text: capsule?.closing ?? '');
    _badCode = TextEditingController(text: capsule?.badCode ?? '');
    _goodCode = TextEditingController(text: capsule?.goodCode ?? '');
    _badCaption = TextEditingController(text: capsule?.badCodeCaption ?? '');
    _goodCaption = TextEditingController(text: capsule?.goodCodeCaption ?? '');

    _tips = [
      for (final tip in capsule?.tips ?? const <CapsuleTip>[])
        _TipFields(tip.title, tip.body),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _headline.dispose();
    _intro.dispose();
    _closing.dispose();
    _badCode.dispose();
    _goodCode.dispose();
    _badCaption.dispose();
    _goodCaption.dispose();
    for (final tip in _tips) {
      tip.dispose();
    }
    super.dispose();
  }

  KnowledgeCapsule? get _result {
    if (_capsule == null) return null;

    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    return (_capsule ??
            const KnowledgeCapsule(
              title: '',
              headline: '',
              intro: '',
              tips: [],
              closing: '',
            ))
        .copyWith(
          title: _title.text.trim(),
          headline: _headline.text.trim(),
          intro: _intro.text.trim(),
          closing: _closing.text.trim(),
          tips: [
            for (final tip in _tips)
              if (tip.hasContent) tip.toTip(),
          ],
          badCode: orNull(_badCode),
          goodCode: orNull(_goodCode),
          badCodeCaption: orNull(_badCaption),
          goodCodeCaption: orNull(_goodCaption),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return EditorScaffold(
      title: 'Cápsula de conocimiento',
      hint: _capsule == null
          ? null
          : 'Consejos breves que resumen lo esencial de la sección.',
      onDelete: _capsule == null
          ? null
          : () async {
              final sure = await confirmDelete(
                context,
                what: 'la cápsula entera',
              );
              if (sure && context.mounted) setState(() => _capsule = null);
            },
      onDone: () => Navigator.of(context).pop(_result),
      child: _capsule == null
          ? EditorEmptyState(
              palette: palette,
              icon: Icons.lightbulb_outline,
              text: 'Esta sección no tiene cápsula de conocimiento.',
              buttonLabel: 'Crear la cápsula',
              onCreate: () => setState(() {
                _capsule = const KnowledgeCapsule(
                  title: 'Cápsula de conocimiento',
                  headline: '',
                  intro: '',
                  tips: [],
                  closing: '',
                );
                _title.text = 'Cápsula de conocimiento';
                _tips = [_TipFields('', '')];
              }),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherCard(
                  palette: palette,
                  child: Column(
                    children: [
                      TeacherField(
                        palette: palette,
                        label: 'Título',
                        controller: _title,
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Frase principal',
                        controller: _headline,
                        maxLines: 2,
                        helper: 'La idea que quieres que se lleven.',
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Introducción',
                        controller: _intro,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SectionMetrics.sectionGap),
                Text(
                  'Consejos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: SectionMetrics.gap),
                for (var i = 0; i < _tips.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TeacherCard(
                      palette: palette,
                      title: 'Consejo ${i + 1}',
                      action: IconButton(
                        tooltip: 'Quitar el consejo ${i + 1}',
                        onPressed: () async {
                          final sure = await confirmDelete(
                            context,
                            what: 'el consejo ${i + 1}',
                          );
                          if (sure) {
                            setState(() {
                              _tips.removeAt(i).dispose();
                              _tips = [..._tips];
                            });
                          }
                        },
                        color: palette.textSecondary,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                      child: Column(
                        children: [
                          TeacherField(
                            palette: palette,
                            label: 'Título',
                            controller: _tips[i].title,
                          ),
                          const SizedBox(height: 10),
                          TeacherField(
                            palette: palette,
                            label: 'Explicación',
                            controller: _tips[i].body,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                TeacherAddButton(
                  palette: palette,
                  label: 'Añadir consejo',
                  onPressed: () =>
                      setState(() => _tips = [..._tips, _TipFields('', '')]),
                ),
                const SizedBox(height: SectionMetrics.sectionGap),
                TeacherCard(
                  palette: palette,
                  title: 'Comparar código (opcional)',
                  child: Column(
                    children: [
                      Text(
                        'Enseñar lo mismo mal y bien escrito es la forma más '
                        'rápida de que se entienda una buena práctica. Si lo '
                        'dejas vacío, no se muestra.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Cómo NO hacerlo',
                        controller: _badCode,
                        maxLines: 6,
                        monospace: true,
                      ),
                      const SizedBox(height: 10),
                      TeacherField(
                        palette: palette,
                        label: 'Qué está mal, en palabras',
                        controller: _badCaption,
                        maxLines: 2,
                      ),
                      const SizedBox(height: SectionMetrics.gap),
                      TeacherField(
                        palette: palette,
                        label: 'Cómo SÍ hacerlo',
                        controller: _goodCode,
                        maxLines: 6,
                        monospace: true,
                      ),
                      const SizedBox(height: 10),
                      TeacherField(
                        palette: palette,
                        label: 'Por qué está mejor, en palabras',
                        controller: _goodCaption,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SectionMetrics.gap),
                TeacherCard(
                  palette: palette,
                  child: TeacherField(
                    palette: palette,
                    label: 'Cierre',
                    controller: _closing,
                    maxLines: 3,
                    helper: 'La última frase de la cápsula.',
                  ),
                ),
              ],
            ),
    );
  }
}

/// Los dos campos de un consejo, con su ciclo de vida.
class _TipFields {
  _TipFields(String title, String body)
    : title = TextEditingController(text: title),
      body = TextEditingController(text: body);

  final TextEditingController title;
  final TextEditingController body;

  bool get hasContent =>
      title.text.trim().isNotEmpty || body.text.trim().isNotEmpty;

  CapsuleTip toTip() =>
      CapsuleTip(title: title.text.trim(), body: body.text.trim());

  void dispose() {
    title.dispose();
    body.dispose();
  }
}
