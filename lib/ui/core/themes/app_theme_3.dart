import 'package:flutter/material.dart';

/// Define los modos visuales disponibles en la aplicación.
/// Incluye opciones para accesibilidad visual y daltonismo.
enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

/// Gestor global del estado del tema.
/// Usa ValueNotifier para redibujar la UI sin dependencias externas.
class ThemeManager {
  static final ValueNotifier<AppThemeMode> themeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  static void changeTheme(AppThemeMode mode) => themeNotifier.value = mode;
}

/// Medidas estándar de la aplicación.
/// Garantiza consistencia en radios, márgenes y tamaños táctiles (accesibilidad).
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

enum AppThemeTone { info, success, warning, danger, action }

/// Extensión para manejar alertas y mensajes (Info, Success, Warning, Danger).
/// Define la triada accesible: fondo suave, borde visible y texto oscuro.
class ActivityThemeColors extends ThemeExtension<ActivityThemeColors> {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color textTitle;
  final Color textSubtitle;
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
  final Color actionBackground;
  final Color actionBorder;
  final Color actionText;

  const ActivityThemeColors({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.textTitle,
    required this.textSubtitle,
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
    required this.actionBackground,
    required this.actionBorder,
    required this.actionText,
  });

  /// Devuelve la triada de colores exacta según la intención.
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
        AppThemeTone.action => (
          background: actionBackground,
          border: actionBorder,
          text: actionText,
        ),
      };

  @override
  ActivityThemeColors copyWith({Color? background}) {
    return ActivityThemeColors(
      background: background ?? this.background,
      border: border,
      iconBackground: iconBackground,
      textTitle: textTitle,
      textSubtitle: textSubtitle,
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
      actionBackground: actionBackground,
      actionBorder: actionBorder,
      actionText: actionText,
    );
  }

  @override
  ActivityThemeColors lerp(
    ThemeExtension<ActivityThemeColors>? other,
    double t,
  ) {
    if (other is! ActivityThemeColors) return this;
    return ActivityThemeColors(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconBackground: Color.lerp(iconBackground, other.iconBackground, t)!,
      textTitle: Color.lerp(textTitle, other.textTitle, t)!,
      textSubtitle: Color.lerp(textSubtitle, other.textSubtitle, t)!,
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
      actionBackground: Color.lerp(
        actionBackground,
        other.actionBackground,
        t,
      )!,
      actionBorder: Color.lerp(actionBorder, other.actionBorder, t)!,
      actionText: Color.lerp(actionText, other.actionText, t)!,
    );
  }
}

/// Extensión para elementos específicos de las lecciones.
class CourseTheme extends ThemeExtension<CourseTheme> {
  final Color lessonCard;
  final Color lessonCardBorder;
  final Color mutedText;
  final Color readingCard;
  final Color knowledgeCapsule;
  final Color progressTrack;

  const CourseTheme({
    required this.lessonCard,
    required this.lessonCardBorder,
    required this.mutedText,
    required this.readingCard,
    required this.knowledgeCapsule,
    required this.progressTrack,
  });

  @override
  CourseTheme copyWith({Color? lessonCard, Color? lessonCardBorder}) =>
      CourseTheme(
        lessonCard: lessonCard ?? this.lessonCard,
        lessonCardBorder: lessonCardBorder ?? this.lessonCardBorder,
        mutedText: mutedText,
        readingCard: readingCard,
        knowledgeCapsule: knowledgeCapsule,
        progressTrack: progressTrack,
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
    );
  }
}

/// Extensión para la consola interactiva de Python.
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

/// Generador dinámico de colores según la temática del módulo.
/// Garantiza alto contraste en textos para accesibilidad visual.
class ModuleCardThemeColors {
  static Color getBackgroundColor(int moduleId) {
    if (moduleId == 1 || moduleId == 2)
      return const Color(0xFFE3F2FD); // Azul suave
    if (moduleId == 3 || moduleId == 4)
      return const Color(0xFFE8F5E9); // Verde suave
    if (moduleId == 5) return const Color(0xFFFFF9C4); // Amarillo suave
    if (moduleId == 6) return const Color(0xFFFFEBEE); // Rojo suave
    return const Color(0xFFF5F5F5); // Default
  }

  static Color getTextColor(int moduleId) {
    if (moduleId == 1 || moduleId == 2)
      return const Color(0xFF0D47A1); // Azul oscuro
    if (moduleId == 3 || moduleId == 4)
      return const Color(0xFF1B5E20); // Verde oscuro
    if (moduleId == 5)
      return const Color(0xFFF57F17); // Amarillo oscuro/naranja
    if (moduleId == 6) return const Color(0xFFB71C1C); // Rojo oscuro
    return const Color(0xFF424242); // Default
  }
}

/// Atajos rápidos para acceder al tema desde el BuildContext.
extension AppThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  CourseTheme get courseTheme => Theme.of(this).extension<CourseTheme>()!;
  CodeConsoleTheme get codeConsoleTheme =>
      Theme.of(this).extension<CodeConsoleTheme>()!;
  ActivityThemeColors get activityColors =>
      Theme.of(this).extension<ActivityThemeColors>()!;
}

/// Fábrica principal que ensambla todos los temas de la aplicación.
class AppTheme {
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
            bodyLarge: baseTextTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: mutedText),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actionsIconTheme: const IconThemeData(size: 28),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: mutedText,
        elevation: 8,
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
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
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
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
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
