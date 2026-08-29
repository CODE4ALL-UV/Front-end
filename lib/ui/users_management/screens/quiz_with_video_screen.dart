import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';
import 'video_player_screen.dart';

class QuizWithVideoScreen extends StatefulWidget {
  final String? actividad;
  const QuizWithVideoScreen({super.key, this.actividad});

  @override
  State<QuizWithVideoScreen> createState() => _QuizWithVideoScreenState();
}

class _QuizWithVideoScreenState extends State<QuizWithVideoScreen> {
  String? _selected;
  bool _largeText = false;
  bool _highContrast = false;

  static const String _videoUrl =
      'https://www.youtube.com/watch?v=nKPbfIU442g&t=89s';

  ColorScheme get _colors => _highContrast
      ? const ColorScheme.highContrastLight()
      : ColorScheme.fromSeed(seedColor: Colors.teal);

  Future<void> _abrirVideo() async {
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoUrl: _videoUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = _largeText ? 1.3 : 1.0;

    return Scaffold(
      backgroundColor: _highContrast ? Colors.black : const Color(0xFFFDFDFD),
      appBar: HeaderWidget(
        title: 'CODE4ALL',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        showUserIcon: true,
        userName: null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),

                // Tarjeta principal con ardilla y pregunta
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _highContrast ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Imagen de la ardilla
                      SizedBox(
                        width: 120,
                        height: 140,
                        child: Image.asset(
                          'assets/images/ardilla_univalle.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selecciona la respuesta indicada',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _highContrast
                                    ? Colors.grey[800]
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Text(
                                '¿Cuál es la sintaxis correcta para imprimir texto en Python?',
                                style: TextStyle(fontSize: 18, height: 1.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        child: const Text(
                          '5',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Video card
                GestureDetector(
                  onTap: _abrirVideo,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: _highContrast
                          ? Colors.grey[850]
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://img.youtube.com/vi/nKPbfIU442g/maxresdefault.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Image.asset(
                                    'assets/images/ardilla_univalle.png',
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Opciones
                _optionButton('print("Hola")'),
                const SizedBox(height: 10),
                _optionButton('echo("Hola")'),
                const SizedBox(height: 10),
                _optionButton('printf("Hola")'),

                const Spacer(),

                // Botón validar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selected == null ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selected == null
                              ? Colors.grey
                              : _colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Validar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionButton(String text) {
    final selected = _selected == text;
    return Semantics(
      button: true,
      label: 'Opción $text',
      child: GestureDetector(
        onTap: () => setState(() => _selected = text),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
