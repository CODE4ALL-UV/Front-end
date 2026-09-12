import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_code4all/youtube_translator_player.dart';

import 'section_activity_scaffold.dart';
import 'sign_camera_screen.dart';
import 'section_theme.dart';
import 'section_widgets.dart';
import 'sign_language_panel.dart';

/// De dónde sale el texto que se ve en el cuadro de subtítulos.
enum _CaptionSource {
  /// Subtítulos reales del video, sincronizados con la reproducción.
  player,

  /// Transcripción escrita de la sección, avanzada frase a frase.
  transcript,
}

/// Videos de apoyo de una sección.
///
/// El video no es nunca la única fuente: junto al reproductor van el cuadro de
/// subtítulos y el panel de alfabeto manual, y debajo la transcripción
/// completa. Un estudiante con discapacidad auditiva obtiene todo el contenido
/// sin depender del audio; uno con discapacidad visual puede escucharlo con el
/// botón "Escuchar" de la barra superior.
class SectionVideoScreen extends StatefulWidget {
  const SectionVideoScreen({
    super.key,
    required this.module,
    required this.section,
  });

  final CourseModule module;
  final CourseSection section;

  @override
  State<SectionVideoScreen> createState() => _SectionVideoScreenState();
}

class _SectionVideoScreenState extends State<SectionVideoScreen> {
  /// Cuánto dura en pantalla cada frase cuando el texto viene de la
  /// transcripción escrita. Da tiempo a leerla y a seguir el deletreo.
  static const Duration _phraseDuration = Duration(seconds: 6);

  int _videoIndex = 0;
  String _caption = '';
  _CaptionSource _source = _CaptionSource.transcript;

  List<String> _phrases = const [];
  int _phraseIndex = 0;
  bool _isPlayingTranscript = false;
  Timer? _phraseTimer;

  /// Cuántos subtítulos devolvió el backend para este video.
  int _cueCount = 0;

  bool _opening = false;

  List<SectionVideo> get _videos => widget.section.videos;
  SectionVideo get _video => _videos[_videoIndex];

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  /// El backend puede no estar configurado; eso no debe tumbar la pantalla.
  String? get _backendUrl {
    try {
      return dotenv.env['BACKEND_URL'];
    } catch (_) {
      return null;
    }
  }

  void _loadPhrases() {
    _phraseTimer?.cancel();
    _phrases = _splitIntoPhrases(_video.transcript);
    _phraseIndex = 0;
    _isPlayingTranscript = false;
    _caption = _phrases.isEmpty ? '' : _phrases.first;
  }

  /// Parte la transcripción en frases legibles de una sola pasada.
  static List<String> _splitIntoPhrases(String transcript) {
    final clean = transcript.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];

    return clean
        .split(RegExp(r'(?<=[.;:])\s+'))
        .map((phrase) => phrase.trim())
        .where((phrase) => phrase.isNotEmpty)
        .toList();
  }

  void _selectVideo(int index) {
    if (index == _videoIndex) return;
    setState(() {
      _videoIndex = index;
      _source = _CaptionSource.transcript;
      _cueCount = 0;
      _loadPhrases();
    });
    announceForAccessibility(
      context,
      'Video ${index + 1} de ${_videos.length}: ${_video.title}',
    );
  }

  void _onCuesLoaded(int count) {
    if (!mounted) return;
    // Que el backend tenga subtítulos no significa que el reproductor los
    // esté emitiendo ya. Solo se anota cuántos hay; la fuente no cambia hasta
    // que llegue el primero de verdad.
    setState(() => _cueCount = count);
  }

  void _onPlayerCaption(String text) {
    if (!mounted || text.trim().isEmpty) return;

    setState(() {
      // El primer subtítulo real del reproductor toma el mando y detiene el
      // avance manual de la transcripción.
      if (_source != _CaptionSource.player) {
        _source = _CaptionSource.player;
        _phraseTimer?.cancel();
        _isPlayingTranscript = false;
      }
      _caption = text;
    });
  }

  void _toggleTranscript() {
    if (_phrases.isEmpty) return;

    setState(() => _isPlayingTranscript = !_isPlayingTranscript);

    if (!_isPlayingTranscript) {
      _phraseTimer?.cancel();
      return;
    }

    _phraseTimer?.cancel();
    _phraseTimer = Timer.periodic(_phraseDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_phraseIndex >= _phrases.length - 1) {
        timer.cancel();
        setState(() => _isPlayingTranscript = false);
        return;
      }
      setState(() {
        _phraseIndex++;
        _caption = _phrases[_phraseIndex];
      });
    });
  }

  void _stepPhrase(int delta) {
    if (_phrases.isEmpty) return;
    final next = (_phraseIndex + delta).clamp(0, _phrases.length - 1);
    if (next == _phraseIndex) return;

    setState(() {
      _phraseIndex = next;
      _caption = _phrases[next];
    });
  }

  Future<void> _openInBrowser() async {
    if (_opening) return;
    setState(() => _opening = true);

    final opened = await openExternalUrl(_video.url);

    if (!mounted) return;
    setState(() => _opening = false);

    _showMessage(
      opened
          ? 'Video abierto en tu navegador'
          : 'No se pudo abrir el video. Copia el enlace y ábrelo manualmente.',
      opened ? SectionTone.success : SectionTone.danger,
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _video.url));
    if (!mounted) return;
    _showMessage('Enlace copiado al portapapeles', SectionTone.success);
  }

  Future<void> _finish() async {
    await CourseProgressStore.instance.markCompleted(
      widget.section.id,
      CourseActivityKind.video,
    );
    if (!mounted) return;

    announceForAccessibility(context, 'Videos marcados como vistos.');
    Navigator.of(context).pop(true);
  }

  /// Muestra el aviso en pantalla y lo anuncia por voz.
  void _showMessage(String message, SectionTone tone) {
    final palette = SectionPalette.of(context);
    announceForAccessibility(context, message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              tone == SectionTone.success
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: palette.tone(tone).foreground,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String get _spokenText {
    final buffer = StringBuffer()
      ..writeln('Video ${_videoIndex + 1} de ${_videos.length}.')
      ..writeln(_video.title)
      ..writeln(_video.description);

    if (_video.transcript.isNotEmpty) {
      buffer
        ..writeln('Resumen del video:')
        ..writeln(_video.transcript);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 640;

    return SectionActivityScaffold(
      moduleLabel: widget.module.label,
      sectionTitle: widget.section.displayTitle,
      activityLabel: 'Video',
      activityIcon: Icons.play_circle_outline,
      spokenText: _spokenText,
      bottomBar: SectionPrimaryButton(
        label: 'Marcar como visto',
        icon: Icons.check_circle_outline,
        tone: SectionTone.success,
        semanticHint: 'Marca los videos de la sección como completados',
        onPressed: _finish,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_videos.length > 1) ...[
            _VideoSelector(
              videos: _videos,
              currentIndex: _videoIndex,
              onSelected: _selectVideo,
            ),
            const SizedBox(height: SectionMetrics.sectionGap),
          ],
          SectionCard(
            background: palette.accentSoft,
            borderColor: palette.accent.withValues(alpha: 0.4),
            child: SectionHeading(
              title: _video.title,
              subtitle: _video.duration.isEmpty
                  ? _video.description
                  : '${_video.description}  ·  Duración ${_video.duration}',
              icon: Icons.ondemand_video_outlined,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: SectionMetrics.sectionGap),
          _PlayerCard(
            key: ValueKey<String>(_video.youtubeId),
            video: _video,
            backendUrl: _backendUrl,
            onCaptionChanged: _onPlayerCaption,
            onCuesLoaded: _onCuesLoaded,
          ),
          const SizedBox(height: SectionMetrics.sectionGap),
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildCaptionBox()),
                  const SizedBox(width: SectionMetrics.gap),
                  Expanded(flex: 2, child: _buildSignPanel()),
                ],
              ),
            )
          else ...[
            _buildCaptionBox(),
            const SizedBox(height: SectionMetrics.gap),
            _buildSignPanel(),
          ],
          const SizedBox(height: SectionMetrics.gap),
          _buildPracticeButton(),
          const SizedBox(height: SectionMetrics.sectionGap),
          _buildSourceNote(palette),
          const SizedBox(height: SectionMetrics.sectionGap),
          _buildFullTranscript(palette),
          const SizedBox(height: SectionMetrics.gap),
          Row(
            children: [
              Expanded(
                child: SectionSecondaryButton(
                  label: 'Copiar enlace',
                  icon: Icons.link,
                  semanticHint: 'Copia la dirección del video',
                  onPressed: _copyLink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionSecondaryButton(
                  label: _opening ? 'Abriendo…' : 'Ver en YouTube',
                  icon: Icons.open_in_new,
                  semanticHint: 'Abre el video en el navegador',
                  onPressed: _opening ? null : _openInBrowser,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCaptionBox() {
    final palette = SectionPalette.of(context);
    final hasPhrases = _phrases.isNotEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.closed_caption, size: 20, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Subtítulos',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.accent,
                  ),
                ),
              ),
              if (_source == _CaptionSource.player)
                const SectionStatusChip(
                  label: 'En vivo',
                  icon: Icons.graphic_eq,
                  tone: SectionTone.success,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 96),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                // Fondo oscuro y texto claro: es el contraste con el que se
                // leen los subtítulos cómodamente, igual que en televisión.
                color: const Color(0xFF10161C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                _caption.isEmpty
                    ? 'Pulsa reproducir para seguir el texto.'
                    : _caption,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: _caption.isEmpty
                      ? const Color(0xFF9AA6B2)
                      : const Color(0xFFF7FAFC),
                ),
              ),
            ),
          ),
          if (_source == _CaptionSource.transcript && hasPhrases) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _CaptionControl(
                  icon: Icons.skip_previous,
                  label: 'Frase anterior',
                  onPressed: _phraseIndex == 0 ? null : () => _stepPhrase(-1),
                ),
                _CaptionControl(
                  icon: _isPlayingTranscript ? Icons.pause : Icons.play_arrow,
                  label: _isPlayingTranscript
                      ? 'Pausar los subtítulos'
                      : 'Reproducir los subtítulos',
                  onPressed: _toggleTranscript,
                ),
                _CaptionControl(
                  icon: Icons.skip_next,
                  label: 'Frase siguiente',
                  onPressed: _phraseIndex >= _phrases.length - 1
                      ? null
                      : () => _stepPhrase(1),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Frase ${_phraseIndex + 1} de ${_phrases.length}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Invita a probar el alfabeto con la cámara.
  ///
  /// Va aquí abajo, y no dentro del panel, porque el panel entero está
  /// excluido de la semántica para no repetir el subtítulo por voz: un botón
  /// ahí dentro sería invisible para un lector de pantalla.
  Widget _buildPracticeButton() {
    return SectionSecondaryButton(
      label: 'Practicar el alfabeto con la cámara',
      icon: Icons.photo_camera_front,
      semanticHint:
          'Abre la cámara para que reconozca las letras que haces con la mano',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SignCameraScreen()),
      ),
    );
  }

  Widget _buildSignPanel() {
    return SignLanguagePanel(
      text: _caption,
      isPlaying: _source == _CaptionSource.player || _isPlayingTranscript,
    );
  }

  Widget _buildSourceNote(SectionPalette palette) {
    if (_source == _CaptionSource.player) {
      return const SectionCallout(
        title: 'Subtítulos del propio video',
        body:
            'El texto del cuadro viene de los subtítulos del video y avanza '
            'con la reproducción. El panel de la derecha deletrea esa misma '
            'frase en alfabeto manual.',
        tone: SectionTone.success,
      );
    }

    if (_cueCount > 0) {
      return const SectionCallout(
        title: 'Dale al play para sincronizar',
        body:
            'Este video tiene subtítulos sincronizados. En cuanto empiece la '
            'reproducción, el cuadro pasará a seguirlos solo. Mientras tanto '
            'puedes leer la transcripción a tu ritmo con los botones.',
      );
    }

    return const SectionCallout(
      title: 'Subtítulos desde la transcripción',
      body:
          'Ahora mismo no hay subtítulos sincronizados disponibles, así que el '
          'cuadro muestra la transcripción escrita de la sección y tú decides '
          'el ritmo con los botones. El contenido es el mismo.',
    );
  }

  Widget _buildFullTranscript(SectionPalette palette) {
    if (_video.transcript.isEmpty) return const SizedBox.shrink();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: 'Transcripción completa',
            subtitle:
                'Todo lo que explica el video, también en texto. No necesitas '
                'el audio para entenderlo.',
            icon: Icons.subtitles_outlined,
          ),
          const SizedBox(height: 14),
          SectionParagraph(_video.transcript),
        ],
      ),
    );
  }
}

/// Selector de video cuando la sección tiene más de uno.
class _VideoSelector extends StatelessWidget {
  const _VideoSelector({
    required this.videos,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<SectionVideo> videos;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: '${videos.length} videos en esta sección',
            subtitle: 'Elige cuál quieres ver. Se recomienda seguir el orden.',
            icon: Icons.video_library_outlined,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < videos.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == videos.length - 1 ? 0 : 8),
              child: Semantics(
                button: true,
                selected: i == currentIndex,
                label:
                    'Video ${i + 1}: ${videos[i].title}. '
                    'Duración ${videos[i].duration}',
                child: ExcludeSemantics(
                  child: Material(
                    color: i == currentIndex
                        ? palette.accentSoft
                        : palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => onSelected(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: SectionMetrics.minTapTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: i == currentIndex
                                ? palette.accent
                                : palette.border,
                            width: i == currentIndex ? 1.8 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              i == currentIndex
                                  ? Icons.play_circle
                                  : Icons.play_circle_outline,
                              size: 24,
                              color: i == currentIndex
                                  ? palette.accent
                                  : palette.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                videos[i].title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.35,
                                  fontWeight: i == currentIndex
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              videos[i].duration,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: palette.textSecondary,
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
        ],
      ),
    );
  }
}

/// Tarjeta con el reproductor embebido.
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    super.key,
    required this.video,
    required this.backendUrl,
    required this.onCaptionChanged,
    required this.onCuesLoaded,
  });

  final SectionVideo video;
  final String? backendUrl;
  final ValueChanged<String> onCaptionChanged;
  final ValueChanged<int> onCuesLoaded;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Semantics(
      label:
          'Reproductor del video ${video.title}. '
          'El texto de lo que se dice aparece debajo, en el cuadro de '
          'subtítulos.',
      // Sin ClipRRect ni AspectRatio alrededor: en web el reproductor es una
      // vista de plataforma (un iframe), y recortarla o volver a imponerle una
      // relación de aspecto puede impedir que los clics lleguen a sus
      // controles. El propio reproductor ya se dibuja en 16:9.
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            border: Border.all(color: palette.border),
          ),
          child: YoutubeTranslatorPlayer(
            videoUrl: video.url,
            backendUrl: backendUrl,
            targetLang: 'es',
            // El subtítulo se muestra en su propio cuadro, con mejor
            // contraste y tamaño ajustable: no hace falta encima del video.
            showOverlayCaption: false,
            onCaptionChanged: onCaptionChanged,
            onCuesLoaded: onCuesLoaded,
          ),
        ),
      ),
    );
  }
}

/// Botón redondo de control de los subtítulos.
class _CaptionControl extends StatelessWidget {
  const _CaptionControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        tooltip: label,
        color: palette.accent,
        disabledColor: palette.textSecondary.withValues(alpha: 0.5),
        constraints: const BoxConstraints(
          minWidth: SectionMetrics.minTapTarget,
          minHeight: SectionMetrics.minTapTarget,
        ),
      ),
    );
  }
}
