import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';

/// Botón de la barra superior con los dos ajustes de lectura: los colores y
/// el tamaño del texto.
///
/// El estudiante los tiene en su menú de ayuda, pero el docente y la
/// dirección no tenían dónde cambiarlos: alguien con baja visión que entrara
/// como docente se quedaba con el tema claro y la letra por defecto.
class AccessibilityQuickButton extends StatelessWidget {
  const AccessibilityQuickButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Accesibilidad: colores y tamaño del texto',
      icon: Icon(Icons.accessibility_new, color: context.colorScheme.onPrimary),
      onPressed: () => showAccessibilitySheet(context),
    );
  }
}

/// Abre el panel de colores y tamaño del texto.
Future<void> showAccessibilitySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _AccessibilitySheet(),
  );
}

/// Los seis temas, con un nombre que se entiende sin saber qué es cada
/// daltonismo.
const List<(AppThemeMode, String, String, IconData)> _themes = [
  (
    AppThemeMode.light,
    'Claro',
    'Fondo blanco, el de siempre',
    Icons.light_mode,
  ),
  (
    AppThemeMode.dark,
    'Oscuro',
    'Fondo negro, cansa menos la vista',
    Icons.dark_mode,
  ),
  (
    AppThemeMode.achromatopsia,
    'Escala de grises',
    'Sin colores, máximo contraste',
    Icons.contrast,
  ),
  (
    AppThemeMode.deuteranopia,
    'Deuteranopía',
    'No distingo bien el verde',
    Icons.visibility,
  ),
  (
    AppThemeMode.protanopia,
    'Protanopía',
    'No distingo bien el rojo',
    Icons.visibility,
  ),
  (
    AppThemeMode.tritanopia,
    'Tritanopía',
    'No distingo bien el azul ni el amarillo',
    Icons.visibility,
  ),
];

class _AccessibilitySheet extends StatelessWidget {
  const _AccessibilitySheet();

  void _announce(BuildContext context, String message) =>
      announceForAccessibility(context, message);

  @override
  Widget build(BuildContext context) {
    final textScale = AccessibilityTextScaleController.global;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([ThemeManager.themeNotifier, textScale]),
          builder: (context, _) {
            final colors = context.colorScheme;
            final current = ThemeManager.themeNotifier.value;
            final percent = (textScale.scale * 100).round();

            // El panel se abre desde la barra superior y heredaba su estilo de
            // botones: iconos blancos. A− y A+ quedaban blancos sobre blanco.
            return IconButtonTheme(
              data: Theme.of(context).iconButtonTheme,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Accesibilidad',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Tamaño del texto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: 'Texto más pequeño',
                        onPressed: textScale.scale <= 0.9
                            ? null
                            : () {
                                textScale.decrease();
                                _announce(
                                  context,
                                  'Texto al ${(textScale.scale * 100).round()} por ciento',
                                );
                              },
                        icon: const Icon(Icons.text_decrease),
                      ),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            '$percent %',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: 'Texto más grande',
                        onPressed: textScale.scale >= 2.0
                            ? null
                            : () {
                                textScale.increase();
                                _announce(
                                  context,
                                  'Texto al ${(textScale.scale * 100).round()} por ciento',
                                );
                              },
                        icon: const Icon(Icons.text_increase),
                      ),
                    ],
                  ),
                  if (textScale.isEnabled)
                    Align(
                      child: TextButton(
                        onPressed: () {
                          textScale.reset();
                          _announce(context, 'Texto a su tamaño normal');
                        },
                        child: const Text('Volver al tamaño normal'),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Colores',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final (mode, name, hint, icon) in _themes)
                    Semantics(
                      selected: mode == current,
                      inMutuallyExclusiveGroup: true,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        minTileHeight: AppMetrics.minTapTarget + 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppMetrics.cardRadius,
                          ),
                          side: BorderSide(
                            color: mode == current
                                ? colors.secondary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        leading: Icon(icon, color: colors.onSurface),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: mode == current
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          hint,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        trailing: mode == current
                            ? Icon(Icons.check_circle, color: colors.secondary)
                            : null,
                        onTap: () {
                          ThemeManager.changeTheme(mode);
                          _announce(context, 'Tema $name activado');
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
