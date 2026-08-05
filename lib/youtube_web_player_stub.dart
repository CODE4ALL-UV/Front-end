import 'package:flutter/material.dart';

class YoutubeWebPlayer extends StatelessWidget {
  final String videoId;

  const YoutubeWebPlayer({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.black12,
      child: const Text(
        'La reproducción web embebida no está disponible en esta plataforma.',
      ),
    );
  }
}
