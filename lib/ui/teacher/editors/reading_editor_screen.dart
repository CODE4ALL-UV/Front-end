import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';

/// La lectura de una sección: sus páginas y, dentro, sus bloques.
///
/// Una lectura larga en una sola pantalla cansa y se pierde el hilo, por eso
/// se divide en páginas. Cada página son bloques: párrafos, listas, código o
/// recuadros destacados. Aquí se ven las páginas; los bloques se editan dentro
/// de cada una.
class ReadingEditorScreen extends StatefulWidget {
  const ReadingEditorScreen({
    super.key,
    required this.reading,
    required this.section,
  });

  final SectionReading? reading;
  final CourseSection section;

  @override
  State<ReadingEditorScreen> createState() => _ReadingEditorScreenState();
}

class _ReadingEditorScreenState extends State<ReadingEditorScreen> {
  SectionReading? _reading;

  late final TextEditingController _title;
  late final TextEditingController _intro;

  @override
  void initState() {
    super.initState();
    _reading = widget.reading;
    _title = TextEditingController(text: _reading?.title ?? '');
    _intro = TextEditingController(text: _reading?.intro ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _create() {
    setState(() {
      _reading = SectionReading(
        title: widget.section.title,
        intro: widget.section.summary,
        pages: const [ReadingPage(title: 'Página 1', summary: '', blocks: [])],
      );
      _title.text = widget.section.title;
      _intro.text = widget.section.summary;
    });
  }

  Future<void> _editPage(int index) async {
    final reading = _reading!;
    final result = await Navigator.of(context).push<ReadingPage>(
      MaterialPageRoute(
        builder: (_) =>
            _PageEditorScreen(page: reading.pages[index], position: index + 1),
      ),
    );
    if (result == null) return;

    setState(() {
      _reading = reading.copyWith(pages: [...reading.pages]..[index] = result);
    });
  }

  void _addPage() {
    final reading = _reading!;
    setState(() {
      _reading = reading.copyWith(
        pages: [
          ...reading.pages,
          ReadingPage(
            title: 'Página ${reading.pages.length + 1}',
            summary: '',
            blocks: const [],
          ),
        ],
      );
    });
  }

  SectionReading? get _result {
    final reading = _reading;
    if (reading == null) return null;
    return reading.copyWith(
      title: _title.text.trim(),
      intro: _intro.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final reading = _reading;

    return EditorScaffold(
      title: 'Lectura',
      hint: reading == null
          ? null
          : 'La lectura se divide en páginas para que el estudiante avance a '
                'su ritmo. Dentro de cada página van los bloques de contenido.',
      onDelete: reading == null
          ? null
          : () async {
              final sure = await confirmDelete(
                context,
                what: 'la lectura entera',
                detail:
                    'Se quitará la lectura de esta sección, con todas sus '
                    'páginas. El resto de actividades no se toca.',
              );
              if (sure && context.mounted) {
                setState(() => _reading = null);
              }
            },
      deleteLabel: 'Quitar la lectura de la sección',
      onDone: () => Navigator.of(context).pop(_result),
      child: reading == null
          ? EditorEmptyState(
              icon: Icons.menu_book,
              text:
                  'Esta sección no tiene lectura.\n'
                  'Se creará con una primera página usando el título y la '
                  'descripción de la sección.',
              buttonLabel: 'Crear la lectura',
              onCreate: _create,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TeacherCard(
                  child: Column(
                    children: [
                      TeacherField(
                        label: 'Título de la lectura',
                        controller: _title,
                      ),
                      const SizedBox(height: AppMetrics.gap),
                      TeacherField(
                        label: 'Introducción',
                        controller: _intro,
                        maxLines: 3,
                        helper: 'Lo primero que se lee al abrir.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppMetrics.sectionGap),
                Text(
                  'Páginas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: appSemanticColors.infoText,
                  ),
                ),
                const SizedBox(height: AppMetrics.gap),
                for (var i = 0; i < reading.pages.length; i++)
                  TeacherListRow(
                    title: reading.pages[i].title,
                    subtitle: reading.pages[i].blocks.isEmpty
                        ? '⚠ sin contenido todavía'
                        : '${reading.pages[i].blocks.length} bloques',
                    position: i + 1,
                    total: reading.pages.length,
                    onTap: () => _editPage(i),
                    onMoveUp: i == 0
                        ? null
                        : () => setState(() {
                            _reading = reading.copyWith(
                              pages: moveItem(reading.pages, i, i - 1),
                            );
                          }),
                    onMoveDown: i == reading.pages.length - 1
                        ? null
                        : () => setState(() {
                            _reading = reading.copyWith(
                              pages: moveItem(reading.pages, i, i + 1),
                            );
                          }),
                    onDelete: reading.pages.length <= 1
                        ? null
                        : () async {
                            final sure = await confirmDelete(
                              context,
                              what: 'la página "${reading.pages[i].title}"',
                            );
                            if (sure) {
                              setState(() {
                                _reading = reading.copyWith(
                                  pages: [...reading.pages]..removeAt(i),
                                );
                              });
                            }
                          },
                  ),
                const SizedBox(height: AppMetrics.gap),
                TeacherAddButton(label: 'Añadir página', onPressed: _addPage),
              ],
            ),
    );
  }
}

/// Una página de la lectura y sus bloques.
class _PageEditorScreen extends StatefulWidget {
  const _PageEditorScreen({required this.page, required this.position});

  final ReadingPage page;
  final int position;

  @override
  State<_PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<_PageEditorScreen> {
  late ReadingPage _page = widget.page;

  late final TextEditingController _title = TextEditingController(
    text: widget.page.title,
  );
  late final TextEditingController _summary = TextEditingController(
    text: widget.page.summary,
  );

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _editBlock(int index) async {
    final result = await Navigator.of(context).push<ReadingBlock>(
      MaterialPageRoute(
        builder: (_) => _BlockEditorScreen(block: _page.blocks[index]),
      ),
    );
    if (result == null) return;

    setState(
      () => _page = _page.copyWith(blocks: [..._page.blocks]..[index] = result),
    );
  }

  Future<void> _addBlock() async {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;
    final kind = await showModalBottomSheet<ReadingBlockKind>(
      context: context,
      backgroundColor: appTheme.infoBackground,
      builder: (context) => const _BlockKindSheet(),
    );
    if (kind == null || !mounted) return;

    final fresh = const ReadingBlock.paragraph(
      title: '',
      body: '',
    ).asKind(kind);

    final result = await Navigator.of(context).push<ReadingBlock>(
      MaterialPageRoute(
        builder: (_) => _BlockEditorScreen(block: fresh, isNew: true),
      ),
    );
    if (result == null) return;

    setState(() => _page = _page.copyWith(blocks: [..._page.blocks, result]));
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return EditorScaffold(
      title: 'Página ${widget.position}',
      onDone: () => Navigator.of(context).pop(
        _page.copyWith(
          title: _title.text.trim(),
          summary: _summary.text.trim(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherCard(
            child: Column(
              children: [
                TeacherField(label: 'Título de la página', controller: _title),
                const SizedBox(height: AppMetrics.gap),
                TeacherField(
                  label: 'Resumen',
                  controller: _summary,
                  maxLines: 2,
                  helper: 'Una línea que adelanta de qué va la página.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.sectionGap),
          Text(
            'Bloques',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: appSemanticColors.infoText,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          if (_page.blocks.isEmpty)
            EditorEmptyState(
              icon: Icons.notes,
              text: 'Esta página todavía no tiene contenido.',
              buttonLabel: 'Añadir el primer bloque',
              onCreate: _addBlock,
            )
          else ...[
            for (var i = 0; i < _page.blocks.length; i++)
              TeacherListRow(
                title: _page.blocks[i].title.isEmpty
                    ? _page.blocks[i].kind.label
                    : _page.blocks[i].title,
                subtitle:
                    '${_page.blocks[i].kind.label} · '
                    '${_page.blocks[i].editorSummary}',
                position: i + 1,
                total: _page.blocks.length,
                leading: Icon(
                  _iconFor(_page.blocks[i].kind),
                  size: 20,
                  color: appSemanticColors.infoText,
                ),
                onTap: () => _editBlock(i),
                onMoveUp: i == 0
                    ? null
                    : () => setState(
                        () => _page = _page.copyWith(
                          blocks: moveItem(_page.blocks, i, i - 1),
                        ),
                      ),
                onMoveDown: i == _page.blocks.length - 1
                    ? null
                    : () => setState(
                        () => _page = _page.copyWith(
                          blocks: moveItem(_page.blocks, i, i + 1),
                        ),
                      ),
                onDelete: () async {
                  final sure = await confirmDelete(
                    context,
                    what: 'este bloque',
                  );
                  if (sure) {
                    setState(
                      () => _page = _page.copyWith(
                        blocks: [..._page.blocks]..removeAt(i),
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: AppMetrics.gap),
            TeacherAddButton(label: 'Añadir bloque', onPressed: _addBlock),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(ReadingBlockKind kind) => switch (kind) {
    ReadingBlockKind.paragraph => Icons.notes,
    ReadingBlockKind.bullets => Icons.format_list_bulleted,
    ReadingBlockKind.steps => Icons.format_list_numbered,
    ReadingBlockKind.code => Icons.code,
    ReadingBlockKind.callout => Icons.campaign_outlined,
  };
}

/// Elegir qué tipo de bloque añadir.
class _BlockKindSheet extends StatelessWidget {
  const _BlockKindSheet();

  static const Map<ReadingBlockKind, String> _what = {
    ReadingBlockKind.paragraph: 'Texto corrido para explicar una idea',
    ReadingBlockKind.bullets: 'Puntos sueltos, sin orden concreto',
    ReadingBlockKind.steps: 'Pasos que hay que seguir en orden',
    ReadingBlockKind.code: 'Un fragmento de Python con su explicación',
    ReadingBlockKind.callout: 'Una idea destacada o un aviso',
  };

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppMetrics.gap),
            child: Text(
              '¿Qué quieres añadir?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: appSemanticColors.infoText,
              ),
            ),
          ),
          for (final kind in ReadingBlockKind.values)
            ListTile(
              title: Text(
                kind.label,
                style: TextStyle(
                  color: appSemanticColors.infoText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _what[kind]!,
                style: TextStyle(
                  color: appSemanticColors.infoText,
                  fontSize: 12.5,
                ),
              ),
              onTap: () => Navigator.of(context).pop(kind),
            ),
          const SizedBox(height: AppMetrics.gap),
        ],
      ),
    );
  }
}

/// Un bloque suelto. Los campos cambian según su tipo.
class _BlockEditorScreen extends StatefulWidget {
  const _BlockEditorScreen({required this.block, this.isNew = false});

  final ReadingBlock block;
  final bool isNew;

  @override
  State<_BlockEditorScreen> createState() => _BlockEditorScreenState();
}

class _BlockEditorScreenState extends State<_BlockEditorScreen> {
  late ReadingBlock _block = widget.block;

  late final TextEditingController _title = TextEditingController(
    text: widget.block.title,
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.block.body,
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.block.code ?? '',
  );
  late final TextEditingController _caption = TextEditingController(
    text: widget.block.codeCaption ?? '',
  );
  late List<TextEditingController> _items = [
    for (final item in widget.block.items) TextEditingController(text: item),
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _code.dispose();
    _caption.dispose();
    for (final controller in _items) {
      controller.dispose();
    }
    super.dispose();
  }

  void _done() {
    final caption = _caption.text.trim();

    Navigator.of(context).pop(
      _block.copyWith(
        title: _title.text.trim(),
        body: _body.text.trim(),
        items: [
          for (final c in _items)
            if (c.text.trim().isNotEmpty) c.text.trim(),
        ],
        code: _code.text,
        codeCaption: caption.isEmpty ? null : caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final kind = _block.kind;
    final isList =
        kind == ReadingBlockKind.bullets || kind == ReadingBlockKind.steps;

    return EditorScaffold(
      title: widget.isNew ? 'Nuevo bloque' : kind.label,
      onDone: _done,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kindPicker(),
                const SizedBox(height: AppMetrics.gap),
                TeacherField(label: 'Título del bloque', controller: _title),
              ],
            ),
          ),
          const SizedBox(height: AppMetrics.gap),

          if (kind != ReadingBlockKind.code || _body.text.isNotEmpty)
            TeacherCard(
              child: TeacherField(
                label: isList ? 'Texto introductorio' : 'Texto',
                controller: _body,
                maxLines: 6,
              ),
            ),

          if (isList) ...[
            const SizedBox(height: AppMetrics.gap),
            TeacherCard(
              title: kind == ReadingBlockKind.steps ? 'Pasos' : 'Puntos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              kind == ReadingBlockKind.steps
                                  ? '${i + 1}.'
                                  : '•',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: appSemanticColors.infoText,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _items[i],
                              style: TextStyle(
                                color: appSemanticColors.infoText,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: appSemanticColors.dangerBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appSemanticColors.infoBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar',
                            onPressed: () => setState(() {
                              _items.removeAt(i).dispose();
                              _items = [..._items];
                            }),
                            color: appSemanticColors.infoText,
                            constraints: const BoxConstraints(
                              minWidth: AppMetrics.minTapTarget,
                              minHeight: AppMetrics.minTapTarget,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  TeacherAddButton(
                    label: kind == ReadingBlockKind.steps
                        ? 'Añadir paso'
                        : 'Añadir punto',
                    onPressed: () => setState(
                      () => _items = [..._items, TextEditingController()],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (kind == ReadingBlockKind.code) ...[
            const SizedBox(height: AppMetrics.gap),
            TeacherCard(
              child: Column(
                children: [
                  TeacherField(
                    label: 'Código',
                    controller: _code,
                    maxLines: 10,
                    monospace: true,
                  ),
                  const SizedBox(height: AppMetrics.gap),
                  TeacherField(
                    label: 'Qué hace este código, en palabras',
                    controller: _caption,
                    maxLines: 2,
                    helper:
                        'Esto es lo que se lee en voz alta en lugar de '
                        'deletrear símbolos. Sin ello, quien usa lector de '
                        'pantalla no entiende el ejemplo.',
                  ),
                ],
              ),
            ),
          ],

          if (kind == ReadingBlockKind.callout) ...[
            const SizedBox(height: AppMetrics.gap),
            TeacherCard(
              title: 'Intención del recuadro',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tone in CalloutTone.values)
                    ChoiceChip(
                      label: Text(tone.label),
                      selected: _block.tone == tone,
                      onSelected: (_) =>
                          setState(() => _block = _block.copyWith()),
                      selectedColor: appSemanticColors.infoText,
                      labelStyle: TextStyle(
                        color: _block.tone == tone
                            ? appSemanticColors.dangerText
                            : appSemanticColors.infoText,
                        fontWeight: _block.tone == tone
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kindPicker() {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de bloque',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: appSemanticColors.infoText,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in ReadingBlockKind.values)
              ChoiceChip(
                label: Text(kind.label),
                selected: _block.kind == kind,
                // Cambiar de tipo conserva lo que quepa en el nuevo: el
                // título y el texto no se pierden al pasar de párrafo a lista.
                onSelected: (_) => setState(() => _block = _block.asKind(kind)),
                selectedColor: appSemanticColors.dangerText,
                labelStyle: TextStyle(
                  color: _block.kind == kind
                      ? appSemanticColors.dangerBorder
                      : appSemanticColors.infoText,
                  fontWeight: _block.kind == kind
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
