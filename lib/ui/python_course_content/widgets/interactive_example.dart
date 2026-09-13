import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';

class EjercicioInteractivoLightScreen extends StatefulWidget {
  final String actividad;

  const EjercicioInteractivoLightScreen({super.key, required this.actividad});

  @override
  State<EjercicioInteractivoLightScreen> createState() =>
      _EjercicioInteractivoLightScreenState();
}

class _EjercicioInteractivoLightScreenState
    extends State<EjercicioInteractivoLightScreen> {
  late final PageController _pageController;
  final List<String?> _selecciones = List.filled(2, null);
  final List<String?> _feedbacks = List.filled(2, null);
  final List<String> _correctas = const [
    'B) Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que tanto principiantes como expertos creen soluciones poderosas',
    'B) Para gestionar e instalar librerías externas',
  ];
  int _currentPage = 0;

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
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF0B4F6C).withValues(alpha: 0.18),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Ejercicio interactivo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Responde correctamente para poder avanzar a la siguiente pregunta.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF2A67AB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Pregunta ${_currentPage + 1} de 2',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                  : const Color(0xFFBBDEFB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: _buildPregunta(
                      index: index,
                      pregunta: index == 0
                          ? '¿Cuál es la razón principal por la cual Python se ha convertido en el lenguaje de programación más relevante del siglo XXI?'
                          : '¿Para qué se utiliza pip en Python?',
                      opciones: index == 0
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
                            ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _goToNextOrFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        _currentPage < 1
                            ? Icons.arrow_forward
                            : Icons.check_circle_outline,
                      ),
                      label: Text(_currentPage < 1 ? 'Siguiente' : 'Terminar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregunta({
    required int index,
    required String pregunta,
    required List<String> opciones,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF90CAF9).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          ...opciones.map(
            (opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _handleSelection(index, opcion),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _selecciones[index] == opcion &&
                            opcion == _correctas[index]
                        ? const Color(0xFF2E7D32)
                        : _selecciones[index] == opcion &&
                              opcion != _correctas[index]
                        ? const Color(0xFFE53935)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _selecciones[index] == opcion &&
                              opcion == _correctas[index]
                          ? const Color(0xFF2E7D32)
                          : _selecciones[index] == opcion &&
                                opcion != _correctas[index]
                          ? const Color(0xFFE53935)
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                  child: Text(
                    opcion,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _selecciones[index] == opcion &&
                              opcion == _correctas[index]
                          ? Colors.white
                          : _selecciones[index] == opcion &&
                                opcion != _correctas[index]
                          ? Colors.white
                          : const Color(0xFF263238),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
