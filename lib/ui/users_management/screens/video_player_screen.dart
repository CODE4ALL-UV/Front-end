import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import '../../../youtube_translator_player.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String? backendUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.backendUrl});

  @override
  Widget build(BuildContext context) {
    final backend = backendUrl ?? ApiService().baseUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Reproductor')),
      body: SafeArea(
        child: YoutubeTranslatorPlayer(
          videoUrl: videoUrl,
          backendUrl: backend,
          targetLang: 'es',
        ),
      ),
    );
  }
}
