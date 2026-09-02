import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';

class QuizScreenDark extends StatefulWidget {
  const QuizScreenDark({super.key});

  @override
  State<QuizScreenDark> createState() => _QuizScreenDarkState();
}

class _QuizScreenDarkState extends State<QuizScreenDark> {
  late final PageController _pageController;
  final List<String?> _selecciones = List.filled(2, null);
  final List<String?> _feedbacks = List.filled(2, null);
  final List<String> _correctas = const [
    'B) Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que tanto principiantes como expertos creen soluciones poderosas',
    'B) Para gestionar e instalar librerías externas',
  ];
  int _currentPage = 0;
  bool _largeText = false;

  ColorScheme get _colors => ColorScheme.fromSeed(
    seedColor: const Color(0xFF60A5FA),
    brightness: Brightness.dark,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSelection(int index, String opcion) {
    setState(() {
      _selecciones[index] = opcion;
      _feedbacks[index] = opcion == _correctas[index]
          ? null
          : 'Respuesta equivocada';
    });
  }

  void _goToNextOrFinish() {
    final seleccionActual = _selecciones[_currentPage];

    if (seleccionActual == null) {
      setState(() {
        _feedbacks[_currentPage] =
            'Selecciona una respuesta antes de continuar.';
      });
      return;
    }

    if (seleccionActual != _correctas[_currentPage]) {
      setState(() {
        _feedbacks[_currentPage] = 'Respuesta equivocada';
      });
      return;
    }

    if (_currentPage < 1) {
      setState(() {
        _currentPage += 1;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado el quiz satisfactoriamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

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
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
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
                              child: Text(
                                _currentPage == 0
                                    ? '¿Cuál es la razón principal por la cual Python se ha convertido en el lenguaje de programación más relevante del siglo XXI?'
                                    : '¿Para qué se utiliza pip en Python?',
                                style: const TextStyle(
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
                        child: Text(
                          '${_currentPage + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: List.generate(2, (index) {
                          final isActive = index == _currentPage;
                          return Expanded(
                            child: Container(
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF455A64),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildQuestionPage(index);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goToNextOrFinish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _currentPage < 1 ? 'Siguiente' : 'Terminar',
                        ),
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

  Widget _buildQuestionPage(int index) {
    final opciones = index == 0
        ? const [
            'A) Porque fue el primer lenguaje de programación creado',
            'B) Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que tanto principiantes como expertos creen soluciones poderosas',
            'C) Porque es el único lenguaje compatible con Windows',
            'D) Porque no requiere descargar ni instalar nada',
          ]
        : const [
            'A) Para escribir código más rápido',
            'B) Para gestionar e instalar librerías externas',
            'C) Para cambiar el color de la terminal',
            'D) Para ejecutar juegos',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...opciones.map(
          (opcion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _optionButton(index, opcion),
          ),
        ),
        if (_feedbacks[index] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _feedbacks[index]!,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _optionButton(int index, String text) {
    final selected = _selecciones[index] == text;
    final isCorrect = text == _correctas[index];
    final isWrongSelected = selected && !isCorrect;
    final showCorrect = isCorrect && _selecciones[index] != null;

    return Semantics(
      button: true,
      label: 'Opción $text',
      child: GestureDetector(
        onTap: () => _handleSelection(index, text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          constraints: const BoxConstraints(minHeight: 46),
          decoration: BoxDecoration(
            color: isWrongSelected
                ? const Color(0xFFE53935)
                : showCorrect
                ? const Color(0xFF2E7D32)
                : selected
                ? const Color(0xFF2563EB)
                : const Color(0xFF111827),
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
              softWrap: true,
              style: TextStyle(
                fontSize: 13,
                color: isWrongSelected || selected || showCorrect
                    ? Colors.white
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
