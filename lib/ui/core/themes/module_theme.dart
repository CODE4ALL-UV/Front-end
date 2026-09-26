import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

class ModuleTheme extends ThemeExtension<ModuleTheme> {
  final Color headerBackground;
  final Color headerIconBackground;
  final Color headerForegroundColor;
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
    required this.headerForegroundColor,
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

    // 1. Determinar Paleta Base o ADN según el Grupo de Módulos
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
      // Módulo 6 (y por defecto): Paleta Roja
      primaryColor = const Color(0xFFE53935);
    }

    // 2. Ajustes de Paleta según el Modo de Daltonismo o Tema Oscuro/Claro
    switch (themeMode) {
      // Ajustes para vista en blanco y negro
      case AppThemeMode.achromatopsia:
        // Todos los módulos usan gris oscuro
        primaryColor = const Color(0xFF424242);
        break;

      case AppThemeMode.deuteranopia:
        // Ajustes para baja sensibilidad al verde
        if (moduleId == 3 && moduleId == 4) {
          // Si entra al módulo verde, lo volvemos un ámbar/mostaza
          primaryColor = const Color(0xFFFF8F00);
        }
        break;

      case AppThemeMode.protanopia:
        // Ajustes para baja sensibilidad al rojo
        if (moduleId == 6) {
          // Si entra al módulo rojo, lo volvemos un azul seguro
          primaryColor = const Color(0xFF0D47A1);
        }
        break;

      case AppThemeMode.tritanopia:
        // Ajustes para baja sencibilidad al azul-amarillo
        if (moduleId == 1 && moduleId == 2) {
          primaryColor = const Color(0xFFC2185B); // Rojo/Rosa accesible
        }
        if (moduleId == 5) {
          primaryColor = const Color(0xFF2E7D32); // Verde/Cian accesible
        }
        break;

      case AppThemeMode.light:
      case AppThemeMode.dark:
        // Mantienen las paletas estándar por módulo
        break;
    }

    // 3. Ajustes de COLORES CONSTANTES (Dependen solo del Light/Dark/Theme)
    // Aquí aplicas tu idea: cosas que NO cambian por el módulo, solo por el tema.
    final Color cardBackground = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF212121);

    // Iconos fijos (ejemplo: Capítulo 1 siempre es morado, Capítulo 2 siempre es naranja, etc.)
    // Excepto si hay acromatopsia, que los volvemos grises.
    final Color fixedIcon1 = themeMode == AppThemeMode.achromatopsia
        ? Colors.grey
        : const Color(0xFF8E24AA);
    final Color fixedIcon2 = themeMode == AppThemeMode.achromatopsia
        ? Colors.grey
        : const Color(0xFF5C6BC0);
    final Color fixedIcon3 = themeMode == AppThemeMode.achromatopsia
        ? Colors.grey
        : const Color(0xFF1976D2);

    // 4. Estructura del MOLDE FINAL (Combinando ADN y Constantes)
    return ModuleTheme(
      // Dinámicos (Usan el ADN del módulo + el truco de withValues para ajustar la opacidad)
      headerBackground: primaryColor,
      headerIconBackground: isDark
          ? primaryColor.withValues(alpha: 0.5)
          : Colors.white.withValues(alpha: 0.3),
      lessonCardBorder: primaryColor.withValues(alpha: 0.4),
      lessonCardNumberBackground: primaryColor,
      progressTrackRemaining: primaryColor.withValues(alpha: 0.1),
      progressTrackFilled: primaryColor,

      // Estáticos (Dependen solo del tema/light/dark)
      headerForegroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF),
      lessonCardBackground: cardBackground,
      lessonCardText: textColor,
      lessonCardNumber: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF),

      // Los íconos fijos de los capítulos que mencionaste
      chapterIconColor1: fixedIcon1,
      chapterIconBackgroundColor1: fixedIcon1.withValues(alpha: 0.15),
      chapterIconColor2: fixedIcon2,
      chapterIconBackgroundColor2: fixedIcon2.withValues(alpha: 0.15),
      chapterIconColor3: fixedIcon3,
      chapterIconBackgroundColor3: fixedIcon3.withValues(alpha: 0.15),
    );
  }

  @override
  ModuleTheme copyWith({
    Color? headerBackground,
    Color? headerIconBackground,
    Color? headerForegroundColor,
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
    headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
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
      headerForegroundColor: Color.lerp(
        headerForegroundColor,
        other.headerForegroundColor,
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
