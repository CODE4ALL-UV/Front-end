/// Piezas que se repiten por todo el editor del docente.
///
/// Están aquí, y no copiadas en cada pantalla, para que un cambio de aspecto
/// —o de tamaño mínimo de un botón— valga para todas a la vez.
library;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

/// Señal de que algo tiene cambios del docente.
///
/// Además del punto de color lleva su etiqueta para el lector de pantalla: un
/// estado que solo se comunica con color deja fuera a quien no lo distingue.
class EditedDot extends StatelessWidget {
  const EditedDot({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // 1. El widget extrae sus propios colores aquí adentro:
    final activityColors = Theme.of(context).extension<ActivityThemeColors>()!;
    return Semantics(
      label: label,
      child: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: activityColors.infoBorder,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Aviso ancho, para cuando algo del entorno no va bien.
class TeacherBanner extends StatelessWidget {
  const TeacherBanner({
    super.key,
    required this.themeColors,
    required this.icon,
    required this.text,
    this.tone,
  });

  final ActivityThemeColors themeColors;
  final IconData icon;
  final String text;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: themeColors.warningBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: themeColors.warningBorder),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: themeColors.warningBorder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de texto del editor, con su etiqueta siempre visible.
///
/// La etiqueta no desaparece al escribir: quien vuelve a un formulario largo
/// necesita saber qué es cada campo sin tener que borrarlo para verlo.
class TeacherField extends StatelessWidget {
  const TeacherField({
    super.key,
    required this.themeColors,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.monospace = false,
    this.onChanged,
  });

  final ActivityThemeColors themeColors;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final int maxLines;

  /// Para código, donde la alineación importa.
  final bool monospace;

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          // El alto de partida no puede pasarse del máximo: un campo de dos
          // líneas no puede abrirse con tres. Flutter lo comprueba y revienta.
          minLines: maxLines <= 1 ? 1 : (maxLines < 3 ? maxLines : 3),
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: theme.colorScheme.primary,
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.colorScheme.secondary,
              fontSize: 14,
            ),
            filled: true,
            fillColor: themeColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(themeColors.cardRadius),
              borderSide: BorderSide(color: themeColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(themeColors.cardRadius),
              borderSide: BorderSide(color: themeColors.accent, width: 2),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: themeColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta que agrupa un trozo del editor.
class TeacherCard extends StatelessWidget {
  const TeacherCard({
    super.key,
    required this.themeColors,
    required this.child,
    this.title,
    this.action,
  });

  final ActivityThemeColors themeColors;
  final Widget child;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // El fondo lo pinta un Material, no la decoración del contenedor. Es lo
    // que permite meter dentro cosas que se pulsan —un ListTile, un
    // interruptor— sin que su efecto de pulsación quede tapado.
    return Material(
      color: themeColors.surface,
      borderRadius: BorderRadius.circular(themeColors.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: themeColors.border),
          borderRadius: BorderRadius.circular(themeColors.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: themeColors.textPrimary,
                      ),
                    ),
                  ),
                  ?action,
                ],
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Botón para añadir algo a una lista.
class TeacherAddButton extends StatelessWidget {
  const TeacherAddButton({
    super.key,
    required this.themeColors,
    required this.label,
    required this.onPressed,
  });

  final ActivityThemeColors themeColors;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: themeColors.accent,
        side: BorderSide(color: themeColors.border),
        minimumSize: const Size(0, themeColors.minTapTarget),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }
}

/// Pide confirmación antes de borrar algo que costó escribir.
Future<bool> confirmDelete(
  BuildContext context, {
  required String what,
  String? detail,
}) async {
  final themeColors = Theme.of(context).extension<ActivityThemeColors>()!;

  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: themeColors.surface,
      title: Text(
        '¿Borrar $what?',
        style: TextStyle(color: themeColors.textPrimary),
      ),
      content: Text(
        detail ?? 'Esto no se puede deshacer una vez guardes la sección.',
        style: TextStyle(color: themeColors.textSecondary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: themeColors.danger,
            foregroundColor: themeColors.onAccent,
          ),
          child: const Text('Borrar'),
        ),
      ],
    ),
  );

  return answer ?? false;
}

/// Fila de una lista que se puede reordenar y borrar.
class TeacherListRow extends StatelessWidget {
  const TeacherListRow({
    super.key,
    required this.themeColors,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.total,
    this.onTap,
    this.onMoveUp,
    this.onMoveDown,
    this.onDelete,
    this.leading,
  });

  final ActivityThemeColors themeColors;
  final String title;
  final String subtitle;
  final int position;
  final int total;
  final VoidCallback? onTap;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDelete;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeColors.surfaceAlt,
        borderRadius: BorderRadius.circular(themeColors.cardRadius),
        border: Border.all(color: themeColors.border),
      ),
      child: Column(
        children: [
          Semantics(
            button: onTap != null,
            label: '$position de $total. $title. $subtitle',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(themeColors.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title.isEmpty ? 'Sin título' : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: title.isEmpty
                                    ? themeColors.textSecondary
                                    : themeColors.textPrimary,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: themeColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.chevron_right,
                          color: themeColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Los controles van en su propia fila, con su etiqueta, porque tres
          // iconos juntos y sin nombre son inservibles por voz.
          Row(
            children: [
              _RowAction(
                themeColors: themeColors,
                icon: Icons.arrow_upward,
                label: 'Subir $title',
                onPressed: onMoveUp,
              ),
              _RowAction(
                themeColors: themeColors,
                icon: Icons.arrow_downward,
                label: 'Bajar $title',
                onPressed: onMoveDown,
              ),
              const Spacer(),
              _RowAction(
                themeColors: themeColors,
                icon: Icons.delete_outline,
                label: 'Borrar $title',
                color: themeColors.danger,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.themeColors,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final ActivityThemeColors themeColors;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      iconSize: 20,
      color: color ?? themeColors.textSecondary,
      constraints: const BoxConstraints(
        minWidth: themeColors.minTapTarget,
        minHeight: themeColors.minTapTarget,
      ),
      icon: Icon(icon),
    );
  }
}

/// Mueve un elemento de una lista una posición.
///
/// Devuelve una lista nueva; no toca la original.
List<T> moveItem<T>(List<T> list, int from, int to) {
  if (from < 0 || from >= list.length) return list;
  if (to < 0 || to >= list.length) return list;

  final copy = [...list];
  final item = copy.removeAt(from);
  copy.insert(to, item);
  return copy;
}
