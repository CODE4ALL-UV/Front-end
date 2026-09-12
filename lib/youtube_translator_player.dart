import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_code4all/web_player_embedded.dart';
import 'package:http/http.dart' as http;

import 'data/services/api_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;

class CaptionCue {
  final Duration start;
  final Duration duration;
  final String text;
  String? translated;

  CaptionCue({
    required this.start,
    required this.duration,
    required this.text,
    this.translated,
  });
}

class YoutubeTranslatorPlayer extends StatefulWidget {
  final String videoUrl;
  final String? backendUrl; // optional
  final String targetLang;

  /// Se llama cada vez que cambia el subtítulo en curso.
  ///
  /// Permite que la pantalla que contiene el reproductor muestre el texto en
  /// su propio cuadro de subtítulos y se lo pase al panel de dactilología.
  final ValueChanged<String>? onCaptionChanged;

  /// Número de subtítulos que se pudieron cargar del backend.
  ///
  /// Si llega 0, quien usa el reproductor sabe que debe recurrir a la
  /// transcripción escrita de la sección.
  final ValueChanged<int>? onCuesLoaded;

  /// Dibuja el subtítulo encima del video.
  ///
  /// Se desactiva cuando la pantalla ya muestra el texto en un cuadro aparte,
  /// para no repetir la misma frase dos veces.
  final bool showOverlayCaption;

  const YoutubeTranslatorPlayer({
    super.key,
    required this.videoUrl,
    this.backendUrl,
    this.targetLang = 'es',
    this.onCaptionChanged,
    this.onCuesLoaded,
    this.showOverlayCaption = true,
  });

  @override
  State<YoutubeTranslatorPlayer> createState() =>
      _YoutubeTranslatorPlayerState();
}

class _YoutubeTranslatorPlayerState extends State<YoutubeTranslatorPlayer> {
  ypf.YoutubePlayerController? _mobileController;
  final List<CaptionCue> _cues = [];
  Timer? _positionTimer;
  String _currentCaption = '';
  bool _loading = true;
  bool _hasValidId = true;

  /// Una sola fuente para la direccion del backend.
  ///
  /// Antes tenia su propio valor por defecto, asi que al desplegar habia que
  /// acordarse de cambiarlo en dos sitios. Ahora cae en ApiService, que ya
  /// sabe leer la que se fija al compilar.
  String get _backendUrl => widget.backendUrl ?? ApiService().baseUrl;

  @override
  void initState() {
    super.initState();
    final id = _extractVideoId(widget.videoUrl);
    if (id == null || id.isEmpty) {
      _hasValidId = false;
      setState(() => _loading = false);
      return;
    }

    if (!kIsWeb) {
      _mobileController = ypf.YoutubePlayerController(
        initialVideoId: id,
        flags: const ypf.YoutubePlayerFlags(autoPlay: false, mute: false),
      );
      _mobileController!.addListener(_onPlayerChanged);
    }

    _fetchCuesFromBackend(id);
  }

  String? _extractVideoId(String url) {
    try {
      final maybe = ypf.YoutubePlayer.convertUrlToId(url);
      if (maybe != null && maybe.isNotEmpty) return maybe;
    } catch (_) {}
    try {
      final uri = Uri.parse(url);
      if ((uri.host.contains('youtube.com') ||
              uri.host.contains('www.youtube.com')) &&
          uri.queryParameters['v'] != null) {
        return uri.queryParameters['v'];
      }
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        if (uri.host.contains('youtu.be')) return segments.first;
        final embedIndex = segments.indexOf('embed');
        if (embedIndex != -1 && segments.length > embedIndex + 1) {
          return segments[embedIndex + 1];
        }
      }
    } catch (_) {}
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) return url;
    return null;
  }

  Future<void> _fetchCuesFromBackend(String videoId) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$_backendUrl/api/youtube/captions').replace(
        queryParameters: {'video_id': videoId, 'target': widget.targetLang},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw Exception('Backend error ${res.statusCode}');
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      final cues = (body['cues'] as List<dynamic>?) ?? [];
      _cues.clear();
      for (var c in cues) {
        final start = Duration(milliseconds: (c['start'] * 1000).toInt());
        final duration = Duration(milliseconds: (c['duration'] * 1000).toInt());
        final text = c['text'] ?? '';
        final translated = c['translated'] as String?;
        _cues.add(
          CaptionCue(
            start: start,
            duration: duration,
            text: text,
            translated: translated,
          ),
        );
      }
      if (!kIsWeb && _mobileController != null && _positionTimer == null) {
        _positionTimer = Timer.periodic(
          const Duration(milliseconds: 200),
          (_) => _updateCaption(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching cues: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        widget.onCuesLoaded?.call(_cues.length);
      }
    }
  }

  void _onPlayerChanged() {}

  void _updateCaption() {
    _updateCaptionAt(_mobileController?.value.position ?? Duration.zero);
  }

  /// Busca el subtitulo que corresponde a [position] y lo publica.
  ///
  /// En movil la posicion la da el controlador nativo; en web la reporta el
  /// reproductor embebido a traves de su stream de estado.
  void _updateCaptionAt(Duration position) {
    final caption = _findCaptionFor(position);
    final text = caption?.translated ?? caption?.text ?? '';
    if (text == _currentCaption) return;

    setState(() => _currentCaption = text);
    widget.onCaptionChanged?.call(text);
  }

  CaptionCue? _findCaptionFor(Duration position) {
    if (_cues.isEmpty) return null;
    int lo = 0, hi = _cues.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final cue = _cues[mid];
      final start = cue.start;
      final end = cue.start + cue.duration;
      if (position < start) {
        hi = mid - 1;
      } else if (position > end) {
        lo = mid + 1;
      } else {
        return cue;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _mobileController?.removeListener(_onPlayerChanged);
    _mobileController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidId) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              SizedBox(height: 8),
              Text(
                'URL o ID de YouTube no válido. Por favor ingresa una URL válida.',
              ),
            ],
          ),
        ),
      );
    }

    final id = _extractVideoId(widget.videoUrl)!;

    final playerWidget = kIsWeb
        ? EmbeddedYoutubeWebPlayer(videoId: id, onPosition: _updateCaptionAt)
        : ypf.YoutubePlayer(
            controller: _mobileController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.redAccent,
          );

    return Stack(
      children: [
        playerWidget,
        if (widget.showOverlayCaption)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _currentCaption.isNotEmpty ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      _currentCaption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_loading)
          const Positioned(
            left: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text('Cargando subtítulos...'),
              ),
            ),
          ),
      ],
    );
  }
}
