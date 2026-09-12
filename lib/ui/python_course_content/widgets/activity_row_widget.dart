//REFACTOR-APROVED x 2 - COLOR TEST REMAINING - DONT TESTED IN UI YET
import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/python_module_model.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

class ActivityRowWidget extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback? onBookTap;
  final VoidCallback? onVideoTap;
  final bool isCompleted;

  const ActivityRowWidget({
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
    final activityColors = Theme.of(context).extension<ActivityThemeColors>()!;
    // Si pasamos alguna función, consideramos que tiene acción
    final hasAction = onBookTap != null || onVideoTap != null;
    final badgeText = _getBadgeText();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: activityColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activityColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activityColors.iconBackground,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: activityColors.textTitle,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actividad educativa',
                  style: TextStyle(
                    fontSize: 12,
                    color: activityColors.textSubtitle,
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
                color: activityColors.successBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: activityColors.successBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: activityColors.successText,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Completado',
                    style: TextStyle(
                      fontSize: 12,
                      color: activityColors.successText,
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
                    color: activityColors.actionBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: activityColors.actionBorder),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: activityColors.actionText,
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
