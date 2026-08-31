import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeIframeTestScreen extends StatefulWidget {
  final String videoId;

  const YoutubeIframeTestScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<YoutubeIframeTestScreen> createState() => _YoutubeIframeTestScreenState();
}

class _YoutubeIframeTestScreenState extends State<YoutubeIframeTestScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true, // Mantenemos ocultos los controles nativos de YouTube cuando IgnorePointer está activo, de lo contrario es true
        showFullscreenButton: false,
        mute: false,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reproductor Personalizado'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // Envolvemos el video en un IgnorePointer para que los clics 
                  // vayan a nuestros botones y no al iframe
                  //child: IgnorePointer(
                    child: YoutubePlayer(
                      controller: _controller,
                      aspectRatio: 16 / 9,
                    ),
                  //),
                ),
              ),
              const SizedBox(height: 24),
              
              // ✨ AQUÍ ESTÁN TUS CONTROLES PERSONALIZADOS EN FLUTTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'play_btn',
                    onPressed: () {
                      _controller.playVideo();
                    },
                    child: const Icon(Icons.play_arrow),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton(
                    heroTag: 'pause_btn',
                    onPressed: () {
                      _controller.pauseVideo();
                    },
                    child: const Icon(Icons.pause),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton(
                    heroTag: 'stop_btn',
                    onPressed: () {
                      _controller.stopVideo();
                    },
                    child: const Icon(Icons.stop),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*
// Web implementation that embeds a simple browser-like frame inside the app.
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

Widget youtubeIframe(String id) {
  final embedUrl = 'https://www.youtube.com/embed/$id?rel=0&playsinline=1';

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'La reproducción embebida no está disponible en esta configuración web.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://www.youtube.com/watch?v=$id');
                
                // Abre el enlace en una nueva pestaña (Web) o en la app de YouTube/Navegador (Móvil)
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text('Abrir video en YouTube'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este bloque mantiene la pantalla de la app abierta y evita la redirección.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
*/