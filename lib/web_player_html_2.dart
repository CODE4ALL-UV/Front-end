import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';

class CustomAudioPlayerScreen extends StatefulWidget {
  const CustomAudioPlayerScreen({super.key});

  @override
  State<CustomAudioPlayerScreen> createState() =>
      _CustomAudioPlayerScreenState();
}

class _CustomAudioPlayerScreenState extends State<CustomAudioPlayerScreen> {
  // Instanciamos el reproductor
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    // Es vital liberar el reproductor de la memoria al salir de la pantalla
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 30),

            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'audio_play',
                  onPressed: () async {
                    // UrlSource se usa para audios en la web.
                    // Si fuera un archivo local usarías AssetSource('ruta.mp3')
                    /*await _audioPlayer.play(
                      UrlSource('Lo_logro_senor_Lo_logre.mp3'),
                    );*/
                    await _audioPlayer.play(
                      AssetSource('audios/Lo_logro_senor_Lo_logre.mp3'),
                    );
                  },
                  child: const Icon(Icons.play_arrow),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'audio_pause',
                  onPressed: () async {
                    await _audioPlayer.pause();
                  },
                  child: const Icon(Icons.pause),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'audio_stop',
                  onPressed: () async {
                    await _audioPlayer.stop();
                  },
                  child: const Icon(Icons.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
