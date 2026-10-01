import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

/// El armazón común de todos los editores del docente.
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
    final appTheme = Theme.of(context);
    final colorScheme = appTheme.colorScheme;

    return Scaffold(
      backgroundColor: appTheme.scaffoldBackgroundColor,
      // «Listo» y «Quitar» viven aquí. Al pasar a la barra común se habían
      // quedado fuera: el docente podía escribir, pero lo escrito no volvía
      // nunca a la sección y no había forma de quitar una actividad.
      appBar: GlobalAppBarWidget(
        title: title,
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: deleteLabel ?? 'Quitar de la sección',
              onPressed: onDelete,
              color: colorScheme.onPrimary,
              icon: const Icon(Icons.delete_outline),
            ),
          // También dentro de un editor se puede salir de la sesión.
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: UserProfileMenu(showName: false),
          ),
          TextButton(
            onPressed: onDone,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(0, AppMetrics.minTapTarget),
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
              padding: AppMetrics.pagePadding(constraints.maxWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppMetrics.maxContentWidth,
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
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppMetrics.sectionGap),
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
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onCreate,
  });

  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppMetrics.sectionGap),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppMetrics.gap),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppMetrics.sectionGap),
          FilledButton.icon(
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(0, AppMetrics.minTapTarget),
            ),
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
