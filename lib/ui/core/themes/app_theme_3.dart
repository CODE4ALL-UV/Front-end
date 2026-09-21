import 'package:flutter/material.dart';

/// Atajos rápidos para acceder al tema desde el BuildContext.
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
  MODOS DE TEMA
  AppThemeMode → Define los 6 modos visuales disponibles:
  light, dark, protanopia, deuteranopia, tritanopia y achromatopsia.
  Acceso: AppThemeMode.light / AppThemeMode.dark
  AppThemeMode.protanopia / AppThemeMode.deuteranopia
  AppThemeMode.tritanopia / AppThemeMode.achromatopsia.

  MÉTRICAS
  AppMetrics → Define valores globales de espaciado, radios, tamaños táctiles y dimensiones.
  No depende del ThemeData ni cambia entre modos de tema.
  Acceso: AppMetrics.cardRadius / AppMetrics.paddingH
          AppMetrics.minTapTarget / etc.

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

enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

abstract final class AppMetrics {
  static const double minTapTarget = 48;
  static const double cardRadius = 16;
  static const double pillRadius = 999;
  static const double gap = 12;
  static const double sectionGap = 20;
  static const double radius = 8.0;
  static const double dialogRadius = 16.0;
  static const double paddingH = 24.0;
  static const double paddingV = 12.0;

  static const double maxContentWidth = 720;

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: width < 380 ? 14 : 20, vertical: 18);

  static final BorderRadius defaultBorder = BorderRadius.circular(radius);
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

class CourseTheme extends ThemeExtension<CourseTheme> {
  final Color lessonCard;
  final Color lessonCardBorder;
  final Color mutedText;
  final Color readingCard;
  final Color knowledgeCapsule;
  final Color progressTrack;
  final Color text;

  const CourseTheme({
    required this.lessonCard,
    required this.lessonCardBorder,
    required this.mutedText,
    required this.readingCard,
    required this.knowledgeCapsule,
    required this.progressTrack,
    required this.text,
  });

  factory CourseTheme.fromModule(int moduleId) {
    if (moduleId == 1 || moduleId == 2) {
      return const CourseTheme(
        lessonCard: Color(0xFFE3F2FD),
        text: Color(0xFF0D47A1),
        lessonCardBorder: Color(0xFF90CAF9),
        mutedText: Color(0xFF64B5F6),
        readingCard: Color(0xFFBBDEFB),
        knowledgeCapsule: Color(0xFF42A5F5),
        progressTrack: Color(0xFF1976D2),
      );
    }

    if (moduleId == 3 || moduleId == 4) {
      return const CourseTheme(
        lessonCard: Color(0xFFE8F5E9),
        text: Color(0xFF1B5E20),
        lessonCardBorder: Color(0xFFA5D6A7),
        mutedText: Color(0xFF81C784),
        readingCard: Color(0xFFC8E6C9),
        knowledgeCapsule: Color(0xFF66BB6A),
        progressTrack: Color(0xFF388E3C),
      );
    }

    if (moduleId == 5) {
      return const CourseTheme(
        lessonCard: Color(0xFFE8F5E9),
        text: Color(0xFF1B5E20),
        lessonCardBorder: Color(0xFFA5D6A7),
        mutedText: Color(0xFF81C784),
        readingCard: Color(0xFFC8E6C9),
        knowledgeCapsule: Color(0xFF66BB6A),
        progressTrack: Color(0xFF388E3C),
      );
    }

    if (moduleId == 6) {
      return const CourseTheme(
        lessonCard: Color(0xFFE8F5E9),
        text: Color(0xFF1B5E20),
        lessonCardBorder: Color(0xFFA5D6A7),
        mutedText: Color(0xFF81C784),
        readingCard: Color(0xFFC8E6C9),
        knowledgeCapsule: Color(0xFF66BB6A),
        progressTrack: Color(0xFF388E3C),
      );
    }

    // Default
    return const CourseTheme(
      lessonCard: Color(0xFFF5F5F5),
      text: Color(0xFF424242),
      lessonCardBorder: Color(0xFFE0E0E0),
      mutedText: Color(0xFF9E9E9E),
      readingCard: Color(0xFFEEEEEE),
      knowledgeCapsule: Color(0xFFBDBDBD),
      progressTrack: Color(0xFF757575),
    );
  }

  @override
  CourseTheme copyWith({
    Color? lessonCard,
    Color? lessonCardBorder,
    Color? mutedText,
    Color? readingCard,
    Color? knowledgeCapsule,
    Color? progressTrack,
    Color? text,
  }) => CourseTheme(
    lessonCard: lessonCard ?? this.lessonCard,
    lessonCardBorder: lessonCardBorder ?? this.lessonCardBorder,
    mutedText: mutedText ?? this.mutedText,
    readingCard: readingCard ?? this.readingCard,
    knowledgeCapsule: knowledgeCapsule ?? this.knowledgeCapsule,
    progressTrack: progressTrack ?? this.progressTrack,
    text: text ?? this.text,
  );

  @override
  CourseTheme lerp(covariant CourseTheme? other, double t) {
    if (other is! CourseTheme) return this;
    return CourseTheme(
      lessonCard: Color.lerp(lessonCard, other.lessonCard, t)!,
      lessonCardBorder: Color.lerp(
        lessonCardBorder,
        other.lessonCardBorder,
        t,
      )!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      readingCard: Color.lerp(readingCard, other.readingCard, t)!,
      knowledgeCapsule: Color.lerp(
        knowledgeCapsule,
        other.knowledgeCapsule,
        t,
      )!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}

class CodeConsoleTheme extends ThemeExtension<CodeConsoleTheme> {
  final Color background;
  final Color border;
  final Color text;
  final Color prompt;
  final Color keyword;
  final Color string;
  final Color comment;
  final Color error;

  const CodeConsoleTheme({
    required this.background,
    required this.border,
    required this.text,
    required this.prompt,
    required this.keyword,
    required this.string,
    required this.comment,
    required this.error,
  });

  @override
  CodeConsoleTheme copyWith({Color? background}) => CodeConsoleTheme(
    background: background ?? this.background,
    border: border,
    text: text,
    prompt: prompt,
    keyword: keyword,
    string: string,
    comment: comment,
    error: error,
  );

  @override
  CodeConsoleTheme lerp(covariant CodeConsoleTheme? other, double t) {
    if (other is! CodeConsoleTheme) return this;
    return CodeConsoleTheme(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      prompt: Color.lerp(prompt, other.prompt, t)!,
      keyword: Color.lerp(keyword, other.keyword, t)!,
      string: Color.lerp(string, other.string, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      error: Color.lerp(error, other.error, t)!,
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
  }) {
    final baseTheme = ThemeData(useMaterial3: true, brightness: brightness);
    final baseTextTheme = baseTheme.textTheme;
    final mutedText = courseTheme.mutedText;

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: baseTextTheme
          .copyWith(
            titleLarge: baseTextTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            titleMedium: baseTextTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600, // Ideal para subtítulos
            ),
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: mutedText),
            bodySmall: baseTextTheme.bodySmall?.copyWith(
              color: mutedText,
              fontSize: 12, // Aseguramos un tamaño legible para textos de apoyo
            ),
            labelLarge: baseTextTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // Los botones (Elevated, TextButton) le inyectarán
              // su onPrimary o secondary automáticamente.
            ),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actionsIconTheme: const IconThemeData(size: 28),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colorScheme
              .onPrimary, // Solo pisamos el color, hereda todo lo demás
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        unselectedItemColor: mutedText,
        elevation: 8.0,
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
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
        labelStyle: TextStyle(color: mutedText),
        hintStyle: TextStyle(color: mutedText),
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
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(color: mutedText),
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

  /// Construye el tema claro (Light).
  /// Primary = Rojo Univalle, Secondary = Azul Python, Tertiary = Amarillo Python.
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFC62828), // Rojo Univalle (Dominante)
      onPrimary: Colors.white,
      secondary: Color(0xFF3776AB), // Azul Python (Secundario)
      onSecondary: Colors.white,
      tertiary: Color(0xFFFFD43B), // Amarillo Python (Auxiliar)
      onTertiary: Color(0xFF212121),
      surface: Colors.white,
      onSurface: Color(0xFF212121),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Colors.white,
      lessonCardBorder: Color(0xFFE3ECF7),
      mutedText: Color(0xFF607D8B),
      readingCard: Color(0xFFE3F2FD),
      knowledgeCapsule: Color(0xFFE8F5E9),
      progressTrack: Color(0xFFE0E0E0),
      text: Color(0xFF212121),
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
      warningText: Color(0xFFE65100), // Corregido para contraste
      dangerBackground: Color(
        0xFFFFEBEE,
      ), // Corregido: Era E53935 (texto no se leía)
      dangerBorder: Color(0xFFEF5350),
      dangerText: Color(0xFFC62828), // Corregido para contraste
    ),
  );

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
