//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/python_module_model.dart';

class DetailCard extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? actionIcon;

  const DetailCard({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Espacio entre el texto y el icono
                actionIcon ??
                    const SizedBox.shrink(), //PILAS PUES if (actionIcon != null) actionIcon!, // <-- 3. Lo muestras si no es nulo
                const Spacer(), // Empuja la flecha de expandir a la derecha
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF424242),
                ),
              ],
            ),
          ),
          if (expanded) ...[const SizedBox(height: 10), child],
        ],
      ),
    );
  }
}

class ActivityItem {
  final String label;
  final String emoji;

  const ActivityItem(this.label, this.emoji);
}

class ActivityRow extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback? onBookTap;
  final VoidCallback? onVideoTap;
  final bool isCompleted;

  const ActivityRow({
    super.key,
    required this.item,
    this.onBookTap,
    this.onVideoTap,
    this.isCompleted = false,
  });

  // Refactorizamos a un switch para mayor limpieza
  String _getBadgeText() {
    switch (item.label) {
      case 'Quiz':
        return 'Comenzar';
      case 'Laboratorio':
      case 'Relevancia del lenguaje Python':
        return 'Explorar';
      case 'Preparando la versión instalada':
        return 'Ver';
      case 'Ejercicio':
      case 'Ejemplo':
      case 'Evaluación final':
      case 'Descarga y puesta en marcha':
      default:
        return 'Abrir';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pasamos alguna función, consideramos que tiene acción
    final hasAction = onBookTap != null || onVideoTap != null;
    final badgeText = _getBadgeText();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263238),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actividad educativa',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF607D8B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF66BB6A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text(
                    'Completado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else if (hasAction)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBookTap ?? onVideoTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
