import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

import '../course_section_edits.dart';
import '../teacher_widgets.dart';
import 'editor_scaffold.dart';

/// Los videos de la sección.
class VideosEditorScreen extends StatefulWidget {
  const VideosEditorScreen({super.key, required this.videos});

  final List<SectionVideo> videos;

  @override
  State<VideosEditorScreen> createState() => _VideosEditorScreenState();
}

class _VideosEditorScreenState extends State<VideosEditorScreen> {
  late List<SectionVideo> _videos = [...widget.videos];

  Future<void> _edit(int index) async {
    final result = await Navigator.of(context).push<SectionVideo>(
      MaterialPageRoute(
        builder: (_) => _VideoEditorScreen(video: _videos[index]),
      ),
    );
    if (result == null) return;
    setState(() => _videos = [..._videos]..[index] = result);
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push<SectionVideo>(
      MaterialPageRoute(
        builder: (_) => const _VideoEditorScreen(
          video: SectionVideo(title: '', youtubeId: '', description: ''),
          isNew: true,
        ),
      ),
    );
    if (result == null) return;
    setState(() => _videos = [..._videos, result]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return EditorScaffold(
      title: 'Videos',
      hint:
          'El estudiante ve estos videos en el orden en que estén aquí, con '
          'sus subtítulos y el panel de señas al lado.',
      onDone: () => Navigator.of(context).pop(_videos),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_videos.isEmpty)
            EditorEmptyState(
              palette: palette,
              icon: Icons.play_circle_outline,
              text: 'Esta sección todavía no tiene videos.',
              buttonLabel: 'Añadir el primer video',
              onCreate: _add,
            )
          else ...[
            for (var i = 0; i < _videos.length; i++)
              TeacherListRow(
                palette: palette,
                title: _videos[i].title,
                subtitle: _videos[i].youtubeId.isEmpty
                    ? '⚠ falta el enlace del video'
                    : '${_videos[i].youtubeId}'
                          '${_videos[i].duration.isEmpty ? "" : " · ${_videos[i].duration}"}'
                          '${_videos[i].transcript.isEmpty ? " · sin transcripción" : ""}',
                position: i + 1,
                total: _videos.length,
                leading: Icon(
                  Icons.play_circle_outline,
                  size: 22,
                  color: palette.danger,
                ),
                onTap: () => _edit(i),
                onMoveUp: i == 0
                    ? null
                    : () =>
                          setState(() => _videos = moveItem(_videos, i, i - 1)),
                onMoveDown: i == _videos.length - 1
                    ? null
                    : () =>
                          setState(() => _videos = moveItem(_videos, i, i + 1)),
                onDelete: () async {
                  final sure = await confirmDelete(
                    context,
                    what: 'el video "${_videos[i].title}"',
                  );
                  if (sure) {
                    setState(() => _videos = [..._videos]..removeAt(i));
                  }
                },
              ),
            const SizedBox(height: SectionMetrics.gap),
            TeacherAddButton(
              palette: palette,
              label: 'Añadir video',
              onPressed: _add,
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoEditorScreen extends StatefulWidget {
  const _VideoEditorScreen({required this.video, this.isNew = false});

  final SectionVideo video;
  final bool isNew;

  @override
  State<_VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<_VideoEditorScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.video.title,
  );
  late final TextEditingController _link = TextEditingController(
    text: widget.video.youtubeId,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.video.description,
  );
  late final TextEditingController _duration = TextEditingController(
    text: widget.video.duration,
  );
  late final TextEditingController _transcript = TextEditingController(
    text: widget.video.transcript,
  );

  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    _description.dispose();
    _duration.dispose();
    _transcript.dispose();
    super.dispose();
  }

  void _done() {
    final id = extractYoutubeId(_link.text);
    if (id == null) {
      setState(
        () => _error =
            'No reconozco ese enlace de YouTube. Pega la dirección completa '
            'del video, o solo su código de 11 caracteres.',
      );
      return;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Ponle un título al video.');
      return;
    }

    Navigator.of(context).pop(
      widget.video.copyWith(
        title: _title.text.trim(),
        youtubeId: id,
        description: _description.text.trim(),
        duration: _duration.text.trim(),
        transcript: _transcript.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final detected = extractYoutubeId(_link.text);

    return EditorScaffold(
      title: widget.isNew ? 'Nuevo video' : 'Editar video',
      onDone: _done,
      child: Column(
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
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: SectionMetrics.gap),
                TeacherField(
                  palette: palette,
                  label: 'Enlace de YouTube',
                  controller: _link,
                  hint: 'https://www.youtube.com/watch?v=...',
                  helper: detected == null
                      ? 'Pega la dirección del video tal cual la copies.'
                      : 'Video reconocido: $detected',
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: SectionMetrics.gap),
                TeacherField(
                  palette: palette,
                  label: 'Duración',
                  controller: _duration,
                  hint: '8:24',
                ),
                const SizedBox(height: SectionMetrics.gap),
                TeacherField(
                  palette: palette,
                  label: 'Descripción',
                  controller: _description,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: SectionMetrics.gap),
          TeacherCard(
            palette: palette,
            child: TeacherField(
              palette: palette,
              label: 'Transcripción',
              controller: _transcript,
              maxLines: 10,
              helper:
                  'Para quien no oye el video. También es lo que alimenta el '
                  'panel de señas cuando YouTube no da subtítulos. Sin ella, '
                  'un estudiante sordo se queda sin el contenido del video.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: SectionMetrics.gap),
            TeacherBanner(
              palette: palette,
              icon: Icons.error_outline,
              text: _error!,
              tone: palette.danger,
            ),
          ],
        ],
      ),
    );
  }
}
