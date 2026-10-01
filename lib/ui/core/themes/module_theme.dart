import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

class ModuleTheme extends ThemeExtension<ModuleTheme> {
  final Color headerBackground;
  final Color headerIconBackground;
  final Color headerForeground;
  final Color chapterIconColor1;
  final Color chapterIconBackgroundColor1;
  final Color chapterIconColor2;
  final Color chapterIconBackgroundColor2;
  final Color chapterIconColor3;
  final Color chapterIconBackgroundColor3;
  final Color lessonCardBackground;
  final Color lessonCardBorder;
  final Color lessonCardText;
  final Color lessonCardNumber;
  final Color lessonCardNumberBackground;
  final Color progressTrackRemaining;
  final Color progressTrackFilled;

  const ModuleTheme({
    required this.headerBackground,
    required this.headerIconBackground,
    required this.headerForeground,
    required this.chapterIconColor1,
    required this.chapterIconBackgroundColor1,
    required this.chapterIconColor2,
    required this.chapterIconBackgroundColor2,
    required this.chapterIconColor3,
    required this.chapterIconBackgroundColor3,
    required this.lessonCardBackground,
    required this.lessonCardBorder,
    required this.lessonCardText,
    required this.lessonCardNumber,
    required this.lessonCardNumberBackground,
    required this.progressTrackRemaining,
    required this.progressTrackFilled,
  });

  factory ModuleTheme.fromModule(int moduleId, AppThemeMode themeMode) {
    final bool isDark = themeMode == AppThemeMode.dark;

    // 1. Color propio de cada grupo de módulos.
    Color primaryColor;

    if (moduleId == 1 || moduleId == 2) {
      // Módulos 1 y 2: Paleta Azul
      primaryColor = const Color(0xFF1565C0);
    } else if (moduleId == 3 || moduleId == 4) {
      // Módulos 3 y 4: Paleta Verde
      primaryColor = const Color(0xFF2E7D32);
    } else if (moduleId == 5) {
      // Módulo 5: Paleta Amarilla
      primaryColor = const Color(0xFFFFCA28);
    } else {
      // Módulo 6 (y por defecto): Paleta Roja. C62828 y no E53935: con
      // texto blanco el segundo se queda en 4,2:1.
      primaryColor = const Color(0xFFC62828);
    }

    // 2. Ajustes según el daltonismo: cada modo cambia los colores que no
    // distingue y deja los demás.
    switch (themeMode) {
      case AppThemeMode.achromatopsia:
        // Todos los módulos usan gris oscuro
        primaryColor = const Color(0xFF424242);
        break;

      case AppThemeMode.deuteranopia:
        // Baja sensibilidad al verde: el módulo verde pasa a ámbar.
        if (moduleId == 3 || moduleId == 4) {
          primaryColor = const Color(0xFFFF8F00);
        }
        break;

      case AppThemeMode.protanopia:
        // Baja sensibilidad al rojo: el módulo rojo pasa a azul.
        if (moduleId == 6) {
          primaryColor = const Color(0xFF0D47A1);
        }
        break;

      case AppThemeMode.tritanopia:
        // Baja sensibilidad al azul y al amarillo.
        if (moduleId == 1 || moduleId == 2) {
          primaryColor = const Color(0xFFC2185B); // Rojo/Rosa accesible
        }
        if (moduleId == 5) {
          primaryColor = const Color(0xFF2E7D32); // Verde accesible
        }
        break;

      case AppThemeMode.light:
      case AppThemeMode.dark:
        // Mantienen las paletas estándar por módulo
        break;
    }

    // En oscuro el mismo tono, pero apagado: un azul o un amarillo puros
    // sobre fondo negro deslumbran.
    if (isDark) {
      final hsl = HSLColor.fromColor(primaryColor);
      primaryColor = hsl
          .withSaturation(hsl.saturation.clamp(0.0, 0.55))
          .withLightness(hsl.lightness.clamp(0.0, 0.32))
          .toColor();
    }

    // 3. Colores que solo dependen del modo claro u oscuro.
    final Color cardBackground = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF212121);

    // Texto encima del color del módulo: blanco o casi negro, el que más
    // contraste. Con el amarillo del módulo 5 el blanco no se leía.
    final Color onPrimary = AppContrast.onColor(primaryColor);

    // Iconos fijos de cada capítulo. En oscuro van en su versión clara para
    // que se vean sobre el fondo, y en acromatopsia en gris.
    final (Color, Color, Color) icons = switch (themeMode) {
      AppThemeMode.achromatopsia => (
        const Color(0xFF424242),
        const Color(0xFF545454),
        const Color(0xFF616161),
      ),
      AppThemeMode.dark => (
        const Color(0xFFCE93D8),
        const Color(0xFF9FA8DA),
        const Color(0xFF90CAF9),
      ),
      AppThemeMode.tritanopia => (
        const Color(0xFFAD1457),
        const Color(0xFF00796B),
        const Color(0xFF5D4037),
      ),
      _ => (
        const Color(0xFF8E24AA),
        const Color(0xFF5C6BC0),
        const Color(0xFF1976D2),
      ),
    };

    // 4. Estructura del MOLDE FINAL (Combinando ADN y Constantes)
    return ModuleTheme(
      headerBackground: primaryColor,
      headerIconBackground: isDark
          ? primaryColor.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.3),
      lessonCardBorder: primaryColor.withValues(alpha: 0.4),
      lessonCardNumberBackground: primaryColor,
      progressTrackRemaining: primaryColor.withValues(alpha: 0.1),
      // La barra de progreso es lo único del color del módulo que va suelto
      // sobre la tarjeta: se ajusta para que se vea (3:1).
      progressTrackFilled: AppContrast.readableOn(
        primaryColor,
        cardBackground,
        AppContrast.ui,
      ),

      headerForeground: onPrimary,
      lessonCardBackground: cardBackground,
      lessonCardText: textColor,
      lessonCardNumber: onPrimary,

      chapterIconColor1: icons.$1,
      chapterIconBackgroundColor1: icons.$1.withValues(alpha: 0.15),
      chapterIconColor2: icons.$2,
      chapterIconBackgroundColor2: icons.$2.withValues(alpha: 0.15),
      chapterIconColor3: icons.$3,
      chapterIconBackgroundColor3: icons.$3.withValues(alpha: 0.15),
    );
  }

  @override
  ModuleTheme copyWith({
    Color? headerBackground,
    Color? headerIconBackground,
    Color? headerForeground,
    Color? chapterIconColor1,
    Color? chapterIconBackgroundColor1,
    Color? chapterIconColor2,
    Color? chapterIconBackgroundColor2,
    Color? chapterIconColor3,
    Color? chapterIconBackgroundColor3,
    Color? lessonCardBackground,
    Color? lessonCardBorder,
    Color? lessonCardText,
    Color? lessonCardNumber,
    Color? lessonCardNumberBackground,
    Color? progressTrackRemaining,
    Color? progressTrackFilled,
  }) => ModuleTheme(
    headerBackground: headerBackground ?? this.headerBackground,
    headerIconBackground: headerIconBackground ?? this.headerIconBackground,
    headerForeground: headerForeground ?? this.headerForeground,
    chapterIconColor1: chapterIconColor1 ?? this.chapterIconColor1,
    chapterIconBackgroundColor1:
        chapterIconBackgroundColor1 ?? this.chapterIconBackgroundColor1,
    chapterIconColor2: chapterIconColor2 ?? this.chapterIconColor2,
    chapterIconBackgroundColor2:
        chapterIconBackgroundColor2 ?? this.chapterIconBackgroundColor2,
    chapterIconColor3: chapterIconColor3 ?? this.chapterIconColor3,
    chapterIconBackgroundColor3:
        chapterIconBackgroundColor3 ?? this.chapterIconBackgroundColor3,
    lessonCardBackground: lessonCardBackground ?? this.lessonCardBackground,
    lessonCardBorder: lessonCardBorder ?? this.lessonCardBorder,
    lessonCardText: lessonCardText ?? this.lessonCardText,
    lessonCardNumber: lessonCardNumber ?? this.lessonCardNumber,
    lessonCardNumberBackground:
        lessonCardNumberBackground ?? this.lessonCardNumberBackground,
    progressTrackRemaining:
        progressTrackRemaining ?? this.progressTrackRemaining,
    progressTrackFilled: progressTrackFilled ?? this.progressTrackFilled,
  );

  @override
  ModuleTheme lerp(covariant ModuleTheme? other, double t) {
    if (other is! ModuleTheme) return this;
    return ModuleTheme(
      headerBackground: Color.lerp(
        headerBackground,
        other.headerBackground,
        t,
      )!,
      headerIconBackground: Color.lerp(
        headerIconBackground,
        other.headerIconBackground,
        t,
      )!,
      headerForeground: Color.lerp(
        headerForeground,
        other.headerForeground,
        t,
      )!,
      chapterIconColor1: Color.lerp(
        chapterIconColor1,
        other.chapterIconColor1,
        t,
      )!,
      chapterIconBackgroundColor1: Color.lerp(
        chapterIconBackgroundColor1,
        other.chapterIconBackgroundColor1,
        t,
      )!,
      chapterIconColor2: Color.lerp(
        chapterIconColor2,
        other.chapterIconColor2,
        t,
      )!,
      chapterIconBackgroundColor2: Color.lerp(
        chapterIconBackgroundColor2,
        other.chapterIconBackgroundColor2,
        t,
      )!,
      chapterIconColor3: Color.lerp(
        chapterIconColor3,
        other.chapterIconColor3,
        t,
      )!,
      chapterIconBackgroundColor3: Color.lerp(
        chapterIconBackgroundColor3,
        other.chapterIconBackgroundColor3,
        t,
      )!,
      lessonCardBackground: Color.lerp(
        lessonCardBackground,
        other.lessonCardBackground,
        t,
      )!,
      lessonCardBorder: Color.lerp(
        lessonCardBorder,
        other.lessonCardBorder,
        t,
      )!,
      lessonCardText: Color.lerp(lessonCardText, other.lessonCardText, t)!,
      lessonCardNumber: Color.lerp(
        lessonCardNumber,
        other.lessonCardNumber,
        t,
      )!,
      lessonCardNumberBackground: Color.lerp(
        lessonCardNumberBackground,
        other.lessonCardNumberBackground,
        t,
      )!,
      progressTrackRemaining: Color.lerp(
        progressTrackRemaining,
        other.progressTrackRemaining,
        t,
      )!,
      progressTrackFilled: Color.lerp(
        progressTrackFilled,
        other.progressTrackFilled,
        t,
      )!,
    );
  }
}
