//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/python_module_model.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_components.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Asegúrate de importar tu GlobalHeaderWidget aquí

class ChapterDetailScreen extends StatefulWidget {
  final ChapterModel chapter; // <-- ¡Un solo objeto con toda la información!
  final List<String>? bottomLabels;

  const ChapterDetailScreen({
    super.key,
    required this.chapter,
    this.bottomLabels,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  // 1. Función auxiliar para decidir qué abrir al tocar el botón de lectura/acción
  VoidCallback? _getOnBookTapAction(ActivityItem item) {
    switch (item.label) {
      case 'Nombre del Tip/Cápsula de conocimiento':
        return () => _openCapsulaConocimiento(item.label);
      case 'Ejemplo':
        return () => _openEjemplo(item.label);
      case 'Ejercicio':
        return () => _openEjercicio(item.label);
      case 'Quiz':
        return () => _openQuiz(item.label);
      case 'Evaluación final':
        return () => _openEvaluacionFinal(item.label);
      case 'Laboratorio':
        return () => _openLaboratorio(item.label);
      default:
        if (item.emoji.contains('📦')) {
          return () => _openLectura(item.label);
        }
        return null;
    }
  }

  // 2. Función auxiliar para decidir qué abrir al tocar el botón de video
  VoidCallback? _getOnVideoTapAction(ActivityItem item) {
    if (item.label == 'Quiz') {
      return () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isDarkTheme // Asumiendo que tienes esta variable accesible
              ? QuizWithVideoScreenDark(actividad: item.label)
              : QuizWithVideoScreen(actividad: item.label),
        ),
      );
    } else if (item.emoji.contains('🖥️')) {
      return () => _openVideo(item.label);
    }
    return null;
  }

  void _openLectura(String actividad) {
    // Aquí puedes dejar tu lógica de navegación
    Navigator.push(
      context,
      MaterialPageRoute(
        // ...
      ),
    );
  }

  void _openVideo(String actividad) {
    // Lógica de navegación a video
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter; // Referencia rápida
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;
    final labels = widget.bottomLabels ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Column(
        children: [
          // Header del Módulo dinámico
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              widget.moduloTitulo, // <-- Usamos la variable del widget
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                16,
              ),
              child: Column(
                children: [
                  _DetailCard(
                    title: widget.capituloTitulo, // <-- Título dinámico
                    expanded: _resumenExpanded,
                    onToggle: () =>
                        setState(() => _resumenExpanded = !_resumenExpanded),
                    child: widget.contenidoResumen, // <-- Contenido dinámico
                  ),
                  const SizedBox(height: 12),
                  DetailCard(
                    title: 'Ruta de actividades',
                    expanded: _rutaExpanded,
                    onToggle: () =>
                        setState(() => _rutaExpanded = !_rutaExpanded),
                    child: Column(
                      children: chapter.rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              // Antes: _ActivityRow(...)
                              // Ahora:
                              child: ActivityRow(
                                item: item,
                                onBookTap: item.hasLectura
                                    ? () => _openLectura(item.label)
                                    : null,
                                onVideoTap: item.hasVideo
                                    ? () => _openVideo(item.label)
                                    : null,
                                // isCompleted: Puedes pasar un booleano aquí cuando tengas esa lógica
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: HelpActionButton(), // Asegúrate de importarlo
            ),
          ),
        ],
      ),
      bottomNavigationBar: MultimodalNavBar(
        previousLabel: labels.isNotEmpty ? labels[0] : null,
        playLabel: labels.length > 1 ? labels[1] : null,
        nextLabel: labels.length > 2 ? labels[2] : null,
      ),
    );
  }
}
