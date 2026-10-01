import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/themes/activity_theme.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/ide_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';

/// Comprueba que los seis temas se puedan leer.
///
/// Los temas existen para personas con baja visión o con daltonismo, así que
/// un color bonito que no contrasta es peor que no tener tema: quien lo elige
/// es justo quien no lo va a poder leer. Se mide con la fórmula de WCAG 2.1:
/// 4,5:1 para texto y 3:1 para iconos, bordes y piezas grandes.
void main() {
  const textMin = 4.5;
  const uiMin = 3.0;

  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  String hex(Color c) =>
      c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  /// Apunta el par si no llega al mínimo. Un color con transparencia se mide
  /// como se ve: mezclado con lo que tiene debajo.
  void check(
    List<String> problems,
    String what,
    Color fg,
    Color bg,
    double min,
  ) {
    final seen = Color.alphaBlend(fg, bg);
    final value = contrast(seen, bg);
    if (value < min) {
      problems.add(
        '$what: ${hex(seen)} sobre ${hex(bg)} = '
        '${value.toStringAsFixed(2)} (mínimo $min)',
      );
    }
  }

  bool isGray(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    final hi = [r, g, b].reduce((x, y) => x > y ? x : y);
    final lo = [r, g, b].reduce((x, y) => x < y ? x : y);
    return hi - lo <= 6;
  }

  for (final mode in AppThemeMode.values) {
    test('el tema ${mode.name} se puede leer', () {
      final problems = <String>[];
      final theme = AppTheme.getTheme(mode: mode);
      final scheme = theme.colorScheme;
      final surface = scheme.surface;
      final scaffold = theme.scaffoldBackgroundColor;

      // Pares básicos de Material.
      check(
        problems,
        'onPrimary/primary',
        scheme.onPrimary,
        scheme.primary,
        textMin,
      );
      check(
        problems,
        'onSecondary/secondary',
        scheme.onSecondary,
        scheme.secondary,
        textMin,
      );
      check(
        problems,
        'onTertiary/tertiary',
        scheme.onTertiary,
        scheme.tertiary,
        textMin,
      );
      check(problems, 'onError/error', scheme.onError, scheme.error, textMin);
      check(problems, 'onSurface/surface', scheme.onSurface, surface, textMin);
      check(problems, 'onSurface/fondo', scheme.onSurface, scaffold, textMin);
      check(
        problems,
        'onSurfaceVariant/surface',
        scheme.onSurfaceVariant,
        surface,
        textMin,
      );
      check(problems, 'error/surface', scheme.error, surface, textMin);
      check(problems, 'outline/surface', scheme.outline, surface, uiMin);
      // TextButton y OutlinedButton escriben en el color secundario.
      check(
        problems,
        'secondary como texto',
        scheme.secondary,
        surface,
        textMin,
      );
      // Casillas, cursor y filas seleccionadas usan el acento del tema (el
      // primario, salvo en oscuro, donde el primario es el gris de la barra).
      final accent = theme.listTileTheme.selectedColor;
      if (accent != null) {
        check(problems, 'acento como texto', accent, surface, textMin);
      }

      // Texto por defecto, campos y diálogos.
      final text = theme.textTheme;
      for (final entry in {
        'bodyLarge': text.bodyLarge,
        'bodyMedium': text.bodyMedium,
        'bodySmall': text.bodySmall,
        'titleLarge': text.titleLarge,
        'titleMedium': text.titleMedium,
      }.entries) {
        final color = entry.value?.color;
        if (color != null) {
          check(problems, '${entry.key}/surface', color, surface, textMin);
          check(problems, '${entry.key}/fondo', color, scaffold, textMin);
        }
      }
      final input = theme.inputDecorationTheme;
      final fill = input.fillColor ?? surface;
      for (final entry in {
        'label del campo': input.labelStyle?.color,
        'pista del campo': input.hintStyle?.color,
      }.entries) {
        if (entry.value != null) {
          check(problems, entry.key, entry.value!, fill, textMin);
        }
      }
      final dialogText = theme.dialogTheme.contentTextStyle?.color;
      if (dialogText != null) {
        check(
          problems,
          'texto del diálogo',
          dialogText,
          theme.dialogTheme.backgroundColor ?? surface,
          textMin,
        );
      }
      final cardBorder =
          (theme.cardTheme.shape as RoundedRectangleBorder?)?.side.color;
      if (cardBorder != null) {
        check(problems, 'borde de tarjeta', cardBorder, surface, 1.2);
      }

      // Avisos: el color fuerte se usa como texto sobre su fondo suave y
      // también suelto sobre la superficie.
      final messages = theme.extension<MessageTheme>()!;
      for (final tone in MessageThemeTone.values) {
        final pair = messages.tone(tone);
        check(
          problems,
          'aviso ${tone.name}',
          pair.foreground,
          pair.background,
          textMin,
        );
        check(
          problems,
          'aviso ${tone.name} sobre surface',
          pair.foreground,
          surface,
          textMin,
        );
      }

      // Actividades: icono y etiqueta en el color fuerte.
      final activities = theme.extension<ActivityTheme>()!;
      for (final tone in ActivityThemeTone.values) {
        final pair = activities.tone(tone);
        check(
          problems,
          'actividad ${tone.name}',
          pair.foreground,
          pair.background,
          textMin,
        );
        check(
          problems,
          'actividad ${tone.name} sobre surface',
          pair.foreground,
          surface,
          uiMin,
        );
      }

      // Consola de Python.
      final console = theme.extension<CodeConsoleTheme>()!;
      for (final entry in {
        'texto': console.text,
        'prompt': console.prompt,
        'palabra clave': console.keyword,
        'cadena': console.string,
        'comentario': console.comment,
        'error': console.error,
      }.entries) {
        check(
          problems,
          'consola ${entry.key}',
          entry.value,
          console.background,
          textMin,
        );
      }

      // Cabecera y tarjetas de cada módulo: cada uno tiene su color.
      for (var module = 1; module <= 6; module++) {
        final m = ModuleTheme.fromModule(module, mode);
        check(
          problems,
          'módulo $module cabecera',
          m.headerForeground,
          m.headerBackground,
          textMin,
        );
        check(
          problems,
          'módulo $module número',
          m.lessonCardNumber,
          m.lessonCardNumberBackground,
          textMin,
        );
        check(
          problems,
          'módulo $module tarjeta',
          m.lessonCardText,
          m.lessonCardBackground,
          textMin,
        );
        check(
          problems,
          'módulo $module progreso',
          m.progressTrackFilled,
          surface,
          uiMin,
        );
        for (final (i, fg, bg) in [
          (1, m.chapterIconColor1, m.chapterIconBackgroundColor1),
          (2, m.chapterIconColor2, m.chapterIconBackgroundColor2),
          (3, m.chapterIconColor3, m.chapterIconBackgroundColor3),
        ]) {
          check(
            problems,
            'módulo $module icono de capítulo $i',
            fg,
            Color.alphaBlend(bg, surface),
            uiMin,
          );
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  test('en modo oscuro las cajas de color no deslumbran', () {
    final theme = AppTheme.getTheme(mode: AppThemeMode.dark);
    final messages = theme.extension<MessageTheme>()!;
    final activities = theme.extension<ActivityTheme>()!;
    final bright = <String>[
      for (final tone in MessageThemeTone.values)
        if (messages.tone(tone).background.computeLuminance() > 0.08)
          'aviso ${tone.name} ${hex(messages.tone(tone).background)}',
      for (final tone in ActivityThemeTone.values)
        if (activities.tone(tone).background.computeLuminance() > 0.08)
          'actividad ${tone.name} ${hex(activities.tone(tone).background)}',
    ];
    expect(bright, isEmpty, reason: bright.join('\n'));
  });

  test('la acromatopsia es gris de verdad, sin un solo color', () {
    final theme = AppTheme.getTheme(mode: AppThemeMode.achromatopsia);
    final scheme = theme.colorScheme;
    final messages = theme.extension<MessageTheme>()!;
    final activities = theme.extension<ActivityTheme>()!;
    final console = theme.extension<CodeConsoleTheme>()!;
    final colored = <String>[
      for (final entry in {
        'primary': scheme.primary,
        'secondary': scheme.secondary,
        'tertiary': scheme.tertiary,
        'error': scheme.error,
        'surface': scheme.surface,
        'fondo': theme.scaffoldBackgroundColor,
      }.entries)
        if (!isGray(entry.value)) '${entry.key} ${hex(entry.value)}',
      for (final tone in MessageThemeTone.values) ...[
        if (!isGray(messages.tone(tone).background)) 'aviso ${tone.name} fondo',
        if (!isGray(messages.tone(tone).foreground)) 'aviso ${tone.name} texto',
      ],
      for (final tone in ActivityThemeTone.values) ...[
        if (!isGray(activities.tone(tone).background))
          'actividad ${tone.name} fondo',
        if (!isGray(activities.tone(tone).foreground))
          'actividad ${tone.name} texto',
      ],
      for (final c in [
        console.keyword,
        console.string,
        console.error,
        console.prompt,
      ])
        if (!isGray(c)) 'consola ${hex(c)}',
      for (var module = 1; module <= 6; module++)
        if (!isGray(
          ModuleTheme.fromModule(
            module,
            AppThemeMode.achromatopsia,
          ).headerBackground,
        ))
          'módulo $module',
    ];
    expect(colored, isEmpty, reason: colored.join('\n'));
  });

  test('cada daltonismo cambia los colores que no distingue', () {
    // Deuteranopía: el verde de los módulos 3 y 4 no se distingue del rojo.
    for (final module in [3, 4]) {
      expect(
        ModuleTheme.fromModule(
          module,
          AppThemeMode.deuteranopia,
        ).headerBackground,
        isNot(
          ModuleTheme.fromModule(module, AppThemeMode.light).headerBackground,
        ),
        reason: 'módulo $module en deuteranopía',
      );
    }
    // Tritanopía: el azul de los módulos 1 y 2 y el amarillo del 5.
    for (final module in [1, 2, 5]) {
      expect(
        ModuleTheme.fromModule(
          module,
          AppThemeMode.tritanopia,
        ).headerBackground,
        isNot(
          ModuleTheme.fromModule(module, AppThemeMode.light).headerBackground,
        ),
        reason: 'módulo $module en tritanopía',
      );
    }
    // Protanopía: el rojo del módulo 6.
    expect(
      ModuleTheme.fromModule(6, AppThemeMode.protanopia).headerBackground,
      isNot(ModuleTheme.fromModule(6, AppThemeMode.light).headerBackground),
    );
  });
}
