import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

/// El armazón común de todos los editores del docente.
///
/// Todos funcionan igual a propósito: se escribe, se pulsa «Listo» y el
/// resultado vuelve a la sección; se sale sin guardar y no cambia nada. Que la
/// forma de salir sea siempre la misma es lo que evita que alguien pierda un
/// texto por no saber dónde estaba el botón esta vez.
class EditorScaffold extends StatelessWidget {
  const EditorScaffold({
    super.key,
    required this.title,
    required this.onDone,
    required this.child,
    this.onDelete,
    this.deleteLabel,
    this.hint,
  });

  final String title;

  /// Devuelve el contenido editado a la pantalla anterior.
  final VoidCallback onDone;

  /// Quita esta actividad de la sección, si se puede quitar.
  final VoidCallback? onDelete;
  final String? deleteLabel;

  /// Una línea que explica qué es esto, para quien lo abre por primera vez.
  final String? hint;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: palette.onAccent,
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: deleteLabel ?? 'Quitar de la sección',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          // Tambien dentro de un editor se puede salir de la sesion.
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: UserProfileMenu(showName: false),
          ),
          TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(
              foregroundColor: palette.onAccent,
              minimumSize: const Size(0, SectionMetrics.minTapTarget),
            ),
            child: const Text(
              'Listo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: SectionMetrics.pagePadding(constraints.maxWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SectionMetrics.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hint != null) ...[
                        Text(
                          hint!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: SectionMetrics.sectionGap),
                      ],
                      child,
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lo que se enseña cuando una actividad todavía no existe.
///
/// Una pantalla en blanco con un botón no dice qué se va a crear. Esto sí.
class EditorEmptyState extends StatelessWidget {
  const EditorEmptyState({
    super.key,
    required this.palette,
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onCreate,
  });

  final SectionPalette palette;
  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SectionMetrics.sectionGap),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: palette.textSecondary),
          const SizedBox(height: SectionMetrics.gap),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: SectionMetrics.sectionGap),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              minimumSize: const Size(0, SectionMetrics.minTapTarget),
            ),
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
