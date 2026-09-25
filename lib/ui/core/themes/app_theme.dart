import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/ide_theme.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900; //OJO: Falta navegador o probar el > 900
  // Todo lo que sea > 900 se considera desktop/pantalla grande
}

/// Atajos rápidos para acceder al tema desde el BuildContext.
/// Acceso: context.colorScheme
///         context.courseTheme
///         context.codeConsoleTheme
///         context.activityColors
extension AppThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  CourseTheme get courseTheme => Theme.of(this).extension<CourseTheme>()!;
  CodeConsoleTheme get codeConsoleTheme =>
      Theme.of(this).extension<CodeConsoleTheme>()!;
  ActivityThemeColors get activityColors =>
      Theme.of(this).extension<ActivityThemeColors>()!;
}

/*
  APP THEME
  Centraliza el sistema visual de la aplicación: temas, colores, métricas,
  estilos de componentes y extensiones específicas de la aplicación.

  GESTIÓN DEL TEMA
  ThemeManager → Mantiene y cambia el modo visual seleccionado mediante ValueNotifier.
  Acceso: ThemeManager.themeNotifier / ThemeManager.changeTheme(...).

  EQUIVALENCIAS
  foregroundColor → color de texto/iconos
  surface         → background
  ----------
  MÉTRICAS
  AppMetrics → Define valores globales de espaciado, radios, tamaños táctiles y dimensiones.
  No depende del ThemeData ni cambia entre modos de tema.
  Acceso: AppMetrics.cardRadius / AppMetrics.paddingH
          AppMetrics.minTapTarget / etc.

  MODOS DE TEMA
  AppThemeMode → Define los 6 modos visuales disponibles:
  light, dark, protanopia, deuteranopia, tritanopia y achromatopsia.
  Acceso: AppThemeMode.light / AppThemeMode.dark
  AppThemeMode.protanopia / AppThemeMode.deuteranopia
  AppThemeMode.tritanopia / AppThemeMode.achromatopsia.

  TONOS SEMÁNTICOS
  AppThemeTone → Identifica la intención visual: info, success, warning o danger.
  Acceso: context.activityColors.tone(AppThemeTone.success)
  Luego: .background / .border / .text
  ----------
  EXTENSIONES PERSONALIZADAS
  ActivityThemeColors → Colores semánticos para información, éxito, advertencia,
  peligro y acciones, incluyendo fondo suave, borde visible y texto oscuro.
  Acceso: Theme.of(context).extension<ActivityThemeColors>()!
          context.activityColors
  
  CourseTheme → Colores específicos de las tarjetas y elementos de las lecciones.
  Acceso: Theme.of(context).extension<CourseTheme>()!
          context.courseTheme

  CodeConsoleTheme → Colores específicos de la consola/editor de código Python.
  Acceso: Theme.of(context).extension<CodeConsoleTheme>()!
          context.codeConsoleTheme
  ----------
  TEMA ACTUAL
  Theme.of(context) → Obtiene el ThemeData aplicado actualmente a la aplicación.
  Acceso: Theme.of(context)

  COLORES MATERIAL
  ColorScheme → Contiene los colores generales de Material 3: primary, secondary,
  tertiary, surface, error, colores para texto/iconos, etc.
  Acceso: Theme.of(context).colorScheme
  Atajo: context.colorScheme

  ESTILOS DE COMPONENTES
  ThemeData → Centraliza la configuración visual de componentes como AppBar, Card,
  botones, campos de texto, diálogos, iconos, progreso, Switch, etc.
  Normalmente los componentes los aplican automáticamente; no es necesario
  acceder manualmente a estas propiedades salvo que se necesite consultar su configuración.
  Acceso: Theme.of(context).appBarTheme
          Theme.of(context).cardTheme
          Theme.of(context).floatingActionButtonTheme / etc.
  
  SINTAXIS DE PYTHON
  pythonLightSyntax / pythonAchromatopsiaSyntax → Define estilos de texto para
  resaltado de sintaxis de Python.
  Acceso: AppTheme.pythonLightSyntax / AppTheme.pythonAchromatopsiaSyntax
          etc....

  CONSTRUCCIÓN DE TEMAS
  AppTheme → Contiene la fábrica común de ThemeData y los temas concretos de la aplicación.
  Acceso: AppTheme.lightTheme / AppTheme.darkTheme
          etc......
*/

class ThemeManager {
  static final ValueNotifier<AppThemeMode> themeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  static void changeTheme(AppThemeMode mode) => themeNotifier.value = mode;
}

abstract final class AppMetrics {
  static const double minTapTarget = 48;
  static const double cardRadius = 16;
  static const double pillRadius = 999;
  static const double gap = 12;
  static const double sectionGap = 20;
  static const double radius = 8.0;
  static const double dialogRadius = 16.0;
  static const double paddingH = 12.0;
  static const double paddingV = 6.0;

  static const double maxContentWidth = 720;

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: width < 380 ? 14 : 20, vertical: 18);

  static final BorderRadius defaultBorder = BorderRadius.circular(radius);
}

enum AppThemeMode {
  light,
  dark,
  achromatopsia, // Monocromático (Escala de grises pura/alto contraste)
  deuteranopia, // Deficiencia Rojo-Verde (Énfasis en Azules y Amarillos)
  protanopia, // Insensibilidad al Rojo (Azul profundo y Dorado)
  tritanopia, // Deficiencia Azul-Amarillo (Rojo/Rosa y Cian/Verde)
}

enum AppThemeTone { info, success, warning, danger }

class ActivityThemeColors extends ThemeExtension<ActivityThemeColors> {
  final Color infoBackground;
  final Color infoBorder;
  final Color infoText;
  final Color successBackground;
  final Color successBorder;
  final Color successText;
  final Color warningBackground;
  final Color warningBorder;
  final Color warningText;
  final Color dangerBackground;
  final Color dangerBorder;
  final Color dangerText;

  const ActivityThemeColors({
    required this.infoBackground,
    required this.infoBorder,
    required this.infoText,
    required this.successBackground,
    required this.successBorder,
    required this.successText,
    required this.warningBackground,
    required this.warningBorder,
    required this.warningText,
    required this.dangerBackground,
    required this.dangerBorder,
    required this.dangerText,
  });

  ({Color background, Color border, Color text}) tone(AppThemeTone tone) =>
      switch (tone) {
        AppThemeTone.info => (
          background: infoBackground,
          border: infoBorder,
          text: infoText,
        ),
        AppThemeTone.success => (
          background: successBackground,
          border: successBorder,
          text: successText,
        ),
        AppThemeTone.warning => (
          background: warningBackground,
          border: warningBorder,
          text: warningText,
        ),
        AppThemeTone.danger => (
          background: dangerBackground,
          border: dangerBorder,
          text: dangerText,
        ),
      };

  @override
  ActivityThemeColors copyWith({Color? background}) {
    return ActivityThemeColors(
      infoBackground: infoBackground,
      infoBorder: infoBorder,
      infoText: infoText,
      successBackground: successBackground,
      successBorder: successBorder,
      successText: successText,
      warningBackground: warningBackground,
      warningBorder: warningBorder,
      warningText: warningText,
      dangerBackground: dangerBackground,
      dangerBorder: dangerBorder,
      dangerText: dangerText,
    );
  }

  @override
  ActivityThemeColors lerp(
    ThemeExtension<ActivityThemeColors>? other,
    double t,
  ) {
    if (other is! ActivityThemeColors) return this;
    return ActivityThemeColors(
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      dangerBackground: Color.lerp(
        dangerBackground,
        other.dangerBackground,
        t,
      )!,
      dangerBorder: Color.lerp(dangerBorder, other.dangerBorder, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
    );
  }
}

class AppTheme {
  /// Ensambla un ThemeData completo a partir de los tokens visuales del tema.
  ///
  /// Parámetros:
  /// - brightness → Define la luminosidad base: Brightness.light o Brightness.dark.
  /// - scaffoldBackgroundColor → Color de fondo general de las pantallas.
  /// - colorScheme → Colores generales de Material 3 y base cromática de los componentes.
  /// - courseTheme → Colores específicos de lecciones y cursos.
  /// - codeConsoleTheme → Colores específicos de la consola/editor de Python.
  /// - activityThemeColors → Colores semánticos para info, success, warning y danger.
  ///
  /// Los valores recibidos se aplican a ThemeData, sus temas de componentes y
  /// sus ThemeExtension personalizadas.
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required ColorScheme colorScheme,
    required CourseTheme courseTheme,
    required CodeConsoleTheme codeConsoleTheme,
    required ActivityThemeColors activityThemeColors,
    required AppThemeMode themeMode,
    required int currentModuleId,
  }) {
    final baseTheme = ThemeData(useMaterial3: true, brightness: brightness);
    final baseTextTheme = baseTheme.textTheme;

    // Generación dinámica de CourseTheme pasando el módulo y el modo activo
    final courseTheme = CourseTheme.fromModule(currentModuleId, themeMode);

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: baseTextTheme
          .copyWith(
            titleLarge: baseTextTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 22,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
            titleMedium: baseTextTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600, // Ideal para subtítulos
            ),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: Colors.black),
            bodySmall: baseTextTheme.bodySmall?.copyWith(
              color: Colors.black,
              fontSize: 12, // Aseguramos un tamaño legible para textos de apoyo
            ),
            labelLarge: baseTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // Los botones (Elevated, TextButton) le inyectarán
              // su onPrimary o secondary automáticamente.
            ),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actionsIconTheme: const IconThemeData(size: 28),
        shadowColor: const Color(0x14000000),
        surfaceTintColor: colorScheme.onPrimary,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colorScheme
              .onPrimary, // Solo pisamos el color, hereda todo lo demás
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: colorScheme.primary,
        elevation: 8.0,
        height: 56.0,
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        shadowColor: const Color(0x14000000),
        surfaceTintColor: colorScheme.onPrimary,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        shadowColor: const Color(0x14000000),
      ),
      splashColor: colorScheme.primary.withValues(alpha: 0.15),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        elevation: 6,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, AppMetrics.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.paddingH,
            vertical: AppMetrics.paddingV,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppMetrics.defaultBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        labelStyle: TextStyle(color: Colors.black),
        hintStyle: TextStyle(color: Colors.black),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: courseTheme.lessonCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.secondary,
            width: 2,
          ), // Usa secundario para input focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.secondary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: Colors.black,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.dialogRadius),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.secondary
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.secondary.withValues(alpha: 0.5)
              : null,
        ),
      ),
      extensions: [courseTheme, codeConsoleTheme, activityThemeColors],
    );
  }

  static ThemeData getTheme({required AppThemeMode mode, int moduleId = 1}) {
    switch (mode) {
      case AppThemeMode.light:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFC62828), // Rojo Univalle
            onPrimary: Colors.white,
            secondary: Color(0xFF4B8BBE), // Azul Python
            onSecondary: Colors.white,
            tertiary: Color(0xFFFFD43B), // Amarillo Python
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF212121),
            error: Color(0xFFD32F2F),
            onError: Colors.white,
          ),
          courseTheme: const CourseTheme(
            headerBackground: Color(0xFF1565C0),
            headerIconBackground: Color(0xFF1E88E5),
            headerForegroundColor: Color(0xFFF3E5F5),
            chapterIconColor1: Color(0xFF1976D2), // OK
            chapterIconBackgroundColor1: Color(0xFFE3F2FD), // OK
            chapterIconColor2: Color(0xFF7B1FA2), // OK
            chapterIconBackgroundColor2: Color(0xFFF3E5F5), //
            chapterIconColor3: Color(0xFF5C6BC0), // OK
            chapterIconBackgroundColor3: Color(0xFFE8EAF6), //
            lessonCardBackground: Colors.white,
            lessonCardBorder: Color(0xFFE3ECF7),
            lessonCardText: Color(0xFF263238),
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF1E88E5),
            progressTrackRemaining: Color(0xFFE8F5E9),
            progressTrackFilled: Color(0xFFE0E0E0),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(0xFFD73A49),
            string: Color(0xFF032F62),
            comment: Color(0xFF6A737D),
            error: Color(0xFFD32F2F),
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFFE3F2FD),
            infoBorder: Color(0xFF90CAF9),
            infoText: Color(0xFF1565C0),
            successBackground: Color(0xFFE8F5E9),
            successBorder: Color(0xFF66BB6A),
            successText: Color(0xFF2E7D32),
            warningBackground: Color(0xFFFFF3E0),
            warningBorder: Color(0xFFFFB74D),
            warningText: Color(0xFFE65100),
            dangerBackground: Color(0xFFFFEBEE),
            dangerBorder: Color(0xFFEF5350),
            dangerText: Color(0xFFC62828),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4B4B4B),
            onPrimary: Color(0xFFFFFFFF),
            secondary: Color(0xFF80CBC4),
            onSecondary: Color(0xFF003731),
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
            error: Color(0xFFEF9A9A),
            onError: Color(0xFF601410),
          ),
          courseTheme: const CourseTheme(
            headerBackground: Color(0xFF0D47A1), // Azul más profundo
            headerIconBackground: Color(0xFF1976D2),
            headerForegroundColor: Color(0xFFFFFFFF),
            chapterIconColor1: Color(
              0xFF64B5F6,
            ), // Azul más claro para resaltar en oscuro
            chapterIconBackgroundColor1: Color(0xFF0D47A1),
            chapterIconColor2: Color(0xFFCE93D8), // Púrpura claro
            chapterIconBackgroundColor2: Color(0xFF4A148C),
            chapterIconColor3: Color(0xFF9FA8DA), // Índigo claro
            chapterIconBackgroundColor3: Color(0xFF1A237E),
            lessonCardBackground: Color(0xFF1E1E1E), // Gris oscuro
            lessonCardBorder: Color(0xFF37474F), // Borde gris azulado oscuro
            lessonCardText: Color(0xFFF8FAFC), // Texto casi blanco
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF1976D2),
            progressTrackRemaining: Color(0xFF263238),
            progressTrackFilled: Color(0xFF42A5F5),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFF121212), // Fondo tipo IDE oscuro
            border: Color(0xFF37474F),
            text: Color(0xFFE0E0E0),
            prompt: Color(0xFF64B5F6),
            keyword: Color(0xFFFF8A65), // Rojo/Naranja desaturado
            string: Color(
              0xFFA5D6A7,
            ), // Verde desaturado (típico de strings en dark mode)
            comment: Color(0xFF78909C),
            error: Color(0xFFEF5350),
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFF0D2840),
            infoBorder: Color(0xFF1976D2),
            infoText: Color(0xFF64B5F6),
            successBackground: Color(0xFF103018),
            successBorder: Color(0xFF388E3C),
            successText: Color(0xFF81C784),
            warningBackground: Color(0xFF3E2723),
            warningBorder: Color(0xFFF57C00),
            warningText: Color(0xFFFFB74D),
            dangerBackground: Color(0xFF3B1314),
            dangerBorder: Color(0xFFD32F2F),
            dangerText: Color(0xFFE57373),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.achromatopsia:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF000000),
            onPrimary: Colors.white,
            secondary: Color(0xFF424242),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF000000),
            error: Color(0xFF000000),
            onError: Colors.white,
          ),
          courseTheme: const CourseTheme(
            headerBackground: Color(0xFF212121), // Gris casi negro
            headerIconBackground: Color(0xFF424242), // Gris medio
            headerForegroundColor: Color(0xFFFFFFFF),
            chapterIconColor1: Color(0xFF424242),
            chapterIconBackgroundColor1: Color(0xFFE0E0E0),
            chapterIconColor2: Color(0xFF616161),
            chapterIconBackgroundColor2: Color(0xFFEEEEEE),
            chapterIconColor3: Color(0xFF757575),
            chapterIconBackgroundColor3: Color(0xFFF5F5F5),
            lessonCardBackground: Colors.white,
            lessonCardBorder: Color(0xFFBDBDBD),
            lessonCardText: Color(0xFF212121),
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF424242),
            progressTrackRemaining: Color(0xFFEEEEEE),
            progressTrackFilled: Color(0xFF424242),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF5F5F5),
            border: Color(0xFF9E9E9E),
            text: Color(0xFF212121),
            prompt: Color(0xFF424242),
            keyword: Color(0xFF000000), // Negro fuerte para destacar
            string: Color(0xFF616161),
            comment: Color(0xFF9E9E9E),
            error: Color(
              0xFF000000,
            ), // En escala de grises, el error es negro puro
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFFF5F5F5),
            infoBorder: Color(0xFF9E9E9E),
            infoText: Color(0xFF424242),
            successBackground: Color(0xFFEEEEEE),
            successBorder: Color(0xFF757575),
            successText: Color(0xFF212121),
            warningBackground: Color(0xFFE0E0E0),
            warningBorder: Color(0xFF616161),
            warningText: Color(0xFF000000),
            dangerBackground: Color(
              0xFFBDBDBD,
            ), // Fondo más oscuro para alerta máxima
            dangerBorder: Color(0xFF424242),
            dangerText: Color(0xFF000000),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.deuteranopia:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0D47A1), // Azul profundo accesible
            onPrimary: Colors.white,
            secondary: Color(0xFFF57F17), // Amarillo/Ámbar
            onSecondary: Colors.black,
            surface: Colors.white,
            onSurface: Color(0xFF0D1B2A),
            error: Color(0xFFB71C1C),
            onError: Colors.white,
          ),
          courseTheme: const CourseTheme(
            headerBackground: Color(0xFF0D47A1), // Azul profundo
            headerIconBackground: Color(0xFF1976D2),
            headerForegroundColor: Color(0xFFFFFFFF),
            chapterIconColor1: Color(0xFF1976D2),
            chapterIconBackgroundColor1: Color(0xFFE3F2FD),
            chapterIconColor2: Color(
              0xFF1565C0,
            ), // Púrpura reemplazado por un azul fuerte
            chapterIconBackgroundColor2: Color(0xFFBBDEFB),
            chapterIconColor3: Color(
              0xFF0277BD,
            ), // Índigo reemplazado por azul cielo
            chapterIconBackgroundColor3: Color(0xFFE1F5FE),
            lessonCardBackground: Colors.white,
            lessonCardBorder: Color(0xFFE3ECF7),
            lessonCardText: Color(0xFF263238),
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF1976D2),
            progressTrackRemaining: Color(0xFFE3F2FD),
            progressTrackFilled: Color(0xFF0288D1),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(0xFFF57C00), // Rojo -> Naranja brillante
            string: Color(0xFF032F62),
            comment: Color(0xFF6A737D),
            error: Color(0xFFE65100), // Rojo -> Naranja quemado muy oscuro
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFFE3F2FD),
            infoBorder: Color(0xFF90CAF9),
            infoText: Color(0xFF1565C0),
            successBackground: Color(0xFFE0F7FA), // Verde -> Cian claro
            successBorder: Color(0xFF4DD0E1), // Cian
            successText: Color(0xFF00838F), // Cian oscuro
            warningBackground: Color(0xFFFFF9C4),
            warningBorder: Color(0xFFFBC02D),
            warningText: Color(0xFFF57F17), // Amarillo fuerte
            dangerBackground: Color(0xFFFFEDE1),
            dangerBorder: Color(0xFFFF9800),
            dangerText: Color(
              0xFFE65100,
            ), // Naranja profundo (sustituto del rojo)
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.protanopia:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF005B96), // Azul seguro
            onPrimary: Colors.white,
            secondary: Color(0xFFFFC107), // Ámbar brillante
            onSecondary: Colors.black,
            surface: Colors.white,
            onSurface: Color(0xFF1A252C),
            error: Color(0xFF8D021F),
            onError: Colors.white,
          ),
          courseTheme: const CourseTheme(
            // La paleta azul se mantiene idéntica al Light Theme, ya que el azul es seguro
            headerBackground: Color(0xFF1565C0),
            headerIconBackground: Color(0xFF1E88E5),
            headerForegroundColor: Color(0xFFFFFFFF),
            chapterIconColor1: Color(0xFF1976D2),
            chapterIconBackgroundColor1: Color(0xFFE3F2FD),
            chapterIconColor2: Color(0xFF8E24AA),
            chapterIconBackgroundColor2: Color(0xFFF3E5F5),
            chapterIconColor3: Color(0xFF5C6BC0),
            chapterIconBackgroundColor3: Color(0xFFE8EAF6),
            lessonCardBackground: Colors.white,
            lessonCardBorder: Color(0xFFE3ECF7),
            lessonCardText: Color(0xFF263238),
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF1E88E5),
            progressTrackRemaining: Color(0xFFE8EAF6),
            progressTrackFilled: Color(0xFF3949AB),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(
              0xFFFFB300,
            ), // Rojo -> Ámbar brillante para ser visible
            string: Color(0xFF032F62),
            comment: Color(0xFF6A737D),
            error: Color(0xFF8E24AA), // Rojo oscuro -> Púrpura/Magenta fuerte
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFFE3F2FD),
            infoBorder: Color(0xFF90CAF9),
            infoText: Color(0xFF1565C0),
            successBackground: Color(
              0xFFE0F2F1,
            ), // Verde -> Teal (verde-azulado)
            successBorder: Color(0xFF4DB6AC),
            successText: Color(0xFF00695C),
            warningBackground: Color(0xFFFFF3E0),
            warningBorder: Color(0xFFFFB74D),
            warningText: Color(0xFFF57C00),
            dangerBackground: Color(0xFFF3E5F5), // Rojo -> Púrpura claro
            dangerBorder: Color(0xFFBA68C8),
            dangerText: Color(0xFF7B1FA2), // Rojo -> Púrpura fuerte
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.tritanopia:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFDF7F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF880E4F), // Rosa/Magenta profundo
            onPrimary: Colors.white,
            secondary: Color(0xFF00838F), // Cian accesible
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF2C001E),
            error: Color(0xFFC62828),
            onError: Colors.white,
          ),
          courseTheme: const CourseTheme(
            headerBackground: Color(0xFF00695C), // Azul -> Teal/Cian oscuro
            headerIconBackground: Color(0xFF00897B),
            headerForegroundColor: Color(0xFFFFFFFF),
            chapterIconColor1: Color(0xFF00897B),
            chapterIconBackgroundColor1: Color(0xFFE0F2F1),
            chapterIconColor2: Color(0xFFD32F2F), // Púrpura -> Rojo oscuro
            chapterIconBackgroundColor2: Color(0xFFFFEBEE),
            chapterIconColor3: Color(0xFFC2185B), // Índigo -> Rosa fuerte
            chapterIconBackgroundColor3: Color(0xFFFCE4EC),
            lessonCardBackground: Colors.white,
            lessonCardBorder: Color(0xFFB2DFDB), // Borde teal claro
            lessonCardText: Color(0xFF263238),
            lessonCardNumber: Color(0xFFFFFFFF),
            lessonCardNumberBackground: Color(0xFF00897B),
            progressTrackRemaining: Color(0xFFE0F2F1),
            progressTrackFilled: Color(0xFF00695C),
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFFAFAFA),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF00695C), // Azul -> Teal
            keyword: Color(0xFFD32F2F), // Rojo (Se mantiene, lo ven bien)
            string: Color(0xFFC2185B), // Azul oscuro -> Rosa oscuro
            comment: Color(0xFF9E9E9E),
            error: Color(0xFFB71C1C), // Rojo muy oscuro
          ),
          activityThemeColors: const ActivityThemeColors(
            infoBackground: Color(0xFFE0F2F1), // Azul -> Teal claro
            infoBorder: Color(0xFF4DB6AC),
            infoText: Color(0xFF00695C),
            successBackground: Color(
              0xFFE8F5E9,
            ), // Verde oscuro (lo ven como rojo/gris, es seguro si es oscuro)
            successBorder: Color(0xFF66BB6A),
            successText: Color(0xFF2E7D32),
            warningBackground: Color(
              0xFFFCE4EC,
            ), // Amarillo/Naranja -> Rosa pálido
            warningBorder: Color(0xFFF06292),
            warningText: Color(0xFFC2185B), // Rosa fuerte
            dangerBackground: Color(0xFFFFEBEE),
            dangerBorder: Color(0xFFE57373),
            dangerText: Color(0xFFC62828), // Rojo
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );
    }
  }

  /// Mapas de resaltado de sintaxis para el editor/consola.
  /// Ideales para usar con paquetes como flutter_highlight.
  static Map<String, TextStyle> get pythonLightSyntax {
    return {
      'keyword': const TextStyle(
        color: Color(0xFFD73A49),
        fontWeight: FontWeight.bold,
      ),
      'string': const TextStyle(
        color: Color(0xFF032F62),
        fontStyle: FontStyle.normal,
      ),
      'comment': const TextStyle(
        color: Color(0xFF6A737D),
        fontStyle: FontStyle.italic,
      ),
      'number': const TextStyle(color: Color(0xFF005CC5)),
      'title': const TextStyle(
        color: Color(0xFF6F42C1),
        fontWeight: FontWeight.bold,
      ),
    };
  }

  static Map<String, TextStyle> get pythonAchromatopsiaSyntax {
    return {
      'keyword': const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
      'string': const TextStyle(
        color: Color(0xFFE0E0E0),
        fontStyle: FontStyle.italic,
      ),
      'comment': const TextStyle(
        color: Color(0xFF757575),
        fontStyle: FontStyle.normal,
      ),
      'number': const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
      'title': const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    };
  }
}
