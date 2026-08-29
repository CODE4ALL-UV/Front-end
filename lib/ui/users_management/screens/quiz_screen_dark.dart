import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';

class QuizScreenDark extends StatefulWidget {
  const QuizScreenDark({super.key});

  @override
  State<QuizScreenDark> createState() => _QuizScreenDarkState();
}

class _QuizScreenDarkState extends State<QuizScreenDark> {
  String? _selected;
  bool _largeText = false;

  ColorScheme get _colors => ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA),
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    final textScale = _largeText ? 1.3 : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: HeaderWidget(
        title: 'CODE4ALL',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              child: const Text(
                                '¿Cuál es la sintaxis correcta para imprimir texto en Python?',
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.25,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2563EB),
                        child: const Text(
                          '5',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _optionButton('print("Hola")'),
                const SizedBox(height: 10),
                _optionButton('echo("Hola")'),
                const SizedBox(height: 10),
                _optionButton('printf("Hola")'),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selected == null ? null : () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selected == null
                              ? const Color(0xFF475569)
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
            color: selected ? const Color(0xFF2563EB) : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF475569)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
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
                color: selected ? Colors.white : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
