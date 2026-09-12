import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
// Asegúrate de importar tu app_theme.dart donde está ActivityThemeColors

class ChapterSummaryWidget extends StatelessWidget {
  final String title;
  final int topicsCount;
  final int capsulesCount;
  final int exercisesCount;
  final int quizzesCount;

  const ChapterSummaryWidget({
    super.key,
    this.title = 'Resumen del capítulo', // Valor por defecto
    required this.topicsCount,
    required this.capsulesCount,
    required this.exercisesCount,
    required this.quizzesCount,
  });

  // Función auxiliar para no repetir código y manejar plurales/singulares
  Widget _buildSummaryItem(
    String emoji,
    int count,
    String singular,
    String plural,
    Color textColor,
  ) {
    if (count == 0) return const SizedBox.shrink(); // Si es 0, no lo dibuja

    final label = count == 1 ? singular : plural;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        '• $emoji $count $label',
        style: TextStyle(
          fontSize: 14,
          color: textColor, // Color dinámico según el tema
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores de tu extensión de tema (la que creamos antes)
    final colors = Theme.of(context).extension<ActivityThemeColors>();

    // Fallbacks por si acaso el tema falla
    final titleColor = colors?.textTitle ?? const Color(0xFF263238);
    final bodyColor = colors?.textTitle ?? Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, // Título dinámico (Ej: "Resumen del Módulo 1")
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: titleColor, // Aplicando el color del Theme
          ),
        ),
        const SizedBox(height: 8),

        // Usamos la función auxiliar para construir la lista limpiamente
        _buildSummaryItem('📖', topicsCount, 'Tema', 'Temas', bodyColor),
        _buildSummaryItem(
          '💡',
          capsulesCount,
          'Cápsula',
          'Cápsulas',
          bodyColor,
        ),
        _buildSummaryItem(
          '🧩',
          exercisesCount,
          'Ejercicio',
          'Ejercicios',
          bodyColor,
        ),
        _buildSummaryItem(
          '📝',
          quizzesCount,
          'Quiz parcial',
          'Quices parciales',
          bodyColor,
        ),
      ],
    );
  }
}
