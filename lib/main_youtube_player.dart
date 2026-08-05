import 'package:flutter/material.dart';
import 'youtube_translator_player.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Duplicate import removed
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Translator Player',
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  );

  @override
  Widget build(BuildContext context) {
    // final service = _makeService(); // Leftover service variable reference removed
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Translator Player')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'YouTube URL'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Cargar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: YoutubeTranslatorPlayer(
              videoUrl: _urlController.text,
              backendUrl: dotenv.env['BACKEND_URL'],
              targetLang: 'es',
            ),
          ),
        ],
      ),
    );
  }
}
