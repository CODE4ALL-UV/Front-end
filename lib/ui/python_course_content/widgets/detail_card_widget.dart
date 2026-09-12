//REFACTOR-APROVED x 2 - COLOR TEST REMAINING - DONT TESTED IN UI YET
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
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: const Color(
                          0xFF212121,
                        ), // O usa onSurface del tema
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (actionIcon != null) ...[
                    const SizedBox(width: 8),
                    actionIcon!,
                  ], // OJO NUEVO EN REFACTOR: Espacio entre el texto y el icono
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
      ),
    );
  }
}
