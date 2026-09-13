import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';

class ReadingTopicScreen extends StatefulWidget {
  final String actividad;
  final String contenido;

  const ReadingTopicScreen({
    super.key,
    required this.actividad,
    required this.contenido,
  });

  @override
  State<ReadingTopicScreen> createState() => ReadingTopicScreenState();
}

class ReadingTopicScreenState extends State<ReadingTopicScreen> {
  static const List<String> _lecturasDisponibles = [
    'Relevancia del lenguaje Python',
    '¿Qué es un IDE/Editor?',
    'Palabras clave',
  ];

  late int _indiceActual;
  bool _lecturaCompletada = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _indiceActual = _lecturasDisponibles.indexOf(widget.actividad);
    if (_indiceActual == -1) {
      _indiceActual = 0;
    }
  }

  void _cambiarLectura(int delta) {
    if (_isFinishing) return;

    if (_indiceActual == _lecturasDisponibles.length - 1 && delta > 0) {
      setState(() {
        _lecturaCompletada = true;
        _isFinishing = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
      return;
    }

    setState(() {
      _indiceActual =
          (_indiceActual + delta + _lecturasDisponibles.length) %
          _lecturasDisponibles.length;
      _lecturaCompletada = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actividadActual = _lecturasDisponibles[_indiceActual];
    final contenidoActual = _textoLecturaPorActividad(actividadActual);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF45D1D6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'Lectura: $actividadActual',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF0B4F6C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Realiza la siguiente lectura',
                    style: TextStyle(
                      fontSize: 44,
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    reverseDuration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>(actividadActual),
                      child: actividadActual == 'Relevancia del lenguaje Python'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LecturaCard(
                                  title: 'Por qué importa',
                                  body:
                                      'Python se ha vuelto clave porque combina una sintaxis clara con una gran capacidad para resolver problemas reales en ciencia de datos, desarrollo web, automatización e inteligencia artificial.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                                const SizedBox(height: 12),
                                _LecturaCard(
                                  title: '¿Dónde se usa?',
                                  body:
                                      'Empresas y equipos tecnológicos lo utilizan para crear prototipos rápidos, servicios digitales y herramientas que conectan distintos sistemas.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                                const SizedBox(height: 12),
                                _LecturaCard(
                                  title: 'Ventajas para aprender',
                                  body:
                                      'Su lectura sencilla y su comunidad activa hacen que aprender Python sea más accesible, más entretenido y más fácil de mantener a lo largo del tiempo.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                              ],
                            )
                          : Text(
                              contenidoActual,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.45,
                                color: Color(0xFF2A67AB),
                              ),
                              textAlign: TextAlign.justify,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF0B4F6C).withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value:
                                  (_indiceActual + 1) /
                                  _lecturasDisponibles.length,
                              minHeight: 8,
                              backgroundColor: const Color(
                                0xFF0B4F6C,
                              ).withValues(alpha: 0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_indiceActual + 1}/${_lecturasDisponibles.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B4F6C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _lecturasDisponibles.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _indiceActual ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _indiceActual
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFF0B4F6C).withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_lecturaCompletada)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFF2E7D32,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Text(
                        '¡Felicitaciones! Has completado la lectura satisfactoriamente.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _cambiarLectura(-1),
                          child: const _NavButton(label: 'Anterior'),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _cambiarLectura(1),
                          child: _NavButton(
                            label:
                                _indiceActual == _lecturasDisponibles.length - 1
                                ? 'Finalizar'
                                : 'Siguiente',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const HelpActionButton(),
            ),
          ),
        ],
      ),
    );
  }
}s