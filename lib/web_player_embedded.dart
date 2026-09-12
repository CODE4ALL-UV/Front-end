import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Reproductor de YouTube pensado para ir **dentro** de otra pantalla.
///
/// A diferencia de [YoutubeIframeTestScreen] —que es una página completa, con
/// su propio `Scaffold`, su barra superior y sus botones— esto es solo el
/// reproductor. Meter una pantalla completa dentro de una tarjeta hacía que se
/// viera la barra roja encima del video, que los controles quedaran fuera de
/// la caja y que el contenido desbordara.
///
/// Además informa de la posición de reproducción, que es lo que permite
/// sincronizar el cuadro de subtítulos y el panel de alfabeto manual.
class EmbeddedYoutubeWebPlayer extends StatefulWidget {
  const EmbeddedYoutubeWebPlayer({
    super.key,
    required this.videoId,
    this.onPosition,
    this.aspectRatio = 16 / 9,
  });

  final String videoId;

  /// Se llama con la posición actual mientras el video avanza.
  final ValueChanged<Duration>? onPosition;

  final double aspectRatio;

  @override
  State<EmbeddedYoutubeWebPlayer> createState() =>
      _EmbeddedYoutubeWebPlayerState();
}

class _EmbeddedYoutubeWebPlayerState extends State<EmbeddedYoutubeWebPlayer> {
  late YoutubePlayerController _controller;
  StreamSubscription<YoutubeVideoState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        // Controles nativos visibles: son los que ya sabe usar cualquiera y
        // los que responden al teclado y al lector de pantalla del navegador.
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        playsInline: true,
        strictRelatedVideos: true,
        // Subtítulos de YouTube encendidos por defecto y en español, para
        // quien prefiera leerlos sobre el propio video.
        enableCaption: true,
        captionLanguage: 'es',
        interfaceLanguage: 'es',
        // Cada cuánto informa de su posición, en milisegundos. Con 300 ms el
        // subtítulo cambia a tiempo sin castigar el rendimiento.
        videoStateUpdateInterval: 300,
      ),
    );

    _stateSubscription = _controller.videoStateStream.listen((state) {
      if (mounted) widget.onPosition?.call(state.position);
    });
  }

  @override
  void didUpdateWidget(covariant EmbeddedYoutubeWebPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _controller.loadVideoById(videoId: widget.videoId);
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: widget.aspectRatio,
      // El arrastre vertical pertenece a la página que contiene el
      // reproductor: si no, desplazarse por la lección abre pantalla completa.
      enableFullScreenOnVerticalDrag: false,
    );
  }
}
