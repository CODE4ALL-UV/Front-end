import 'package:flutter/material.dart';
// Definimos los tipos de temas que soporta tu app
enum AppThemeMode {
  light,
  dark,
  protanopia,
  deuteranopia,
  tritanopia,
  achromatopsia,
}

class ThemeManager {
  // ValueNotifier global que ahora maneja el ENUM en lugar de un booleano
  static final ValueNotifier<AppThemeMode> themeNotifier = 
      ValueNotifier<AppThemeMode>(AppThemeMode.light);
      //USAR ESTE OTRO SI ALGO
      //static final ValueNotifier<AppThemeMode> themeNotifier = ValueNotifier(AppThemeMode.light);

  static void changeTheme(AppThemeMode mode) {
    themeNotifier.value = mode;
  }
}
/// Define los seis temas visuales disponibles en la aplicación.
///
/// Cada getter declara únicamente su paleta. [_buildTheme] aplica los estilos
/// Material compartidos para que ninguna paleta quede incompleta.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFE53935),
      onPrimary: Colors.white,
      secondary: Color(0xFF5C6BC0),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF212121),
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Colors.white,
      lessonCardBorder: Color(0xFFE3F2FD),
      mutedText: Color(0xFF607D8B),
      readingCard: Color(0xFFEAF7FF),
      knowledgeCapsule: Color(0xFFE8F5E9),
      progressTrack: Color(0xFFE3F2FD),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFB0BEC5),
      text: Color(0xFF263238),
      prompt: Color(0xFF1E88E5),
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
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );

  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF90CAF9),
      onPrimary: Color(0xFF003258),
      secondary: Color(0xFF80CBC4),
      onSecondary: Color(0xFF003731),
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white,
      error: Color(0xFFEF9A9A),
      onError: Color(0xFF601410),
    ),
    courseTheme: const CourseTheme(
      lessonCard: Color(0xFF1E1E1E),
      lessonCardBorder: Color(0xFF334155),
      mutedText: Color(0xFFB0BEC5),
      readingCard: Color(0xFF1B3A4B),
      knowledgeCapsule: Color(0xFF1F2D31),
      progressTrack: Color(0xFF263238),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Color(0xFF1F2937),
      border: Color(0xFF334155),
      text: Color(0xFFF8FAFC),
      prompt: Color(0xFF80DEEA),
      keyword: Color(0xFF90CAF9),
      string: Color(0xFFE0C97D),
      comment: Color(0xFF94A3B8),
      error: Color(0xFFEF9A9A),
    ),
    activityThemeColors: const ActivityThemeColors(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );

  static ThemeData get protanopiaTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0055B7),
      onPrimary: Colors.white,
      secondary: Color(0xFF5B2C83),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF111827),
      error: Color(0xFF7F1D1D),
      onError: Colors.white,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Colors.white,
      lessonCardBorder: Color(0xFF0055B7),
      mutedText: Color(0xFF374151),
      readingCard: Color(0xFFEAF4FF),
      knowledgeCapsule: Color(0xFFF3F4F6),
      progressTrack: Color(0xFFDCEBFA),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Color(0xFFF8FAFC),
      border: Color(0xFF0055B7),
      text: Color(0xFF111827),
      prompt: Color(0xFF0055B7),
      keyword: Color(0xFF5B2C83),
      string: Color(0xFF6B3E00),
      comment: Color(0xFF4B5563),
      error: Color(0xFF7F1D1D),
    ),
    activityThemeColors: const ActivityThemeColors(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );

  static ThemeData get deuteranopiaTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF002F6C),
      onPrimary: Colors.white,
      secondary: Color(0xFF6B21A8),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      error: Color(0xFF991B1B),
      onError: Colors.white,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Colors.white,
      lessonCardBorder: Color(0xFF002F6C),
      mutedText: Color(0xFF334155),
      readingCard: Color(0xFFF7F2E8),
      knowledgeCapsule: Color(0xFFF3F4F6),
      progressTrack: Color(0xFFE6D4A8),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Color(0xFFF8FAFC),
      border: Color(0xFF002F6C),
      text: Color(0xFF111827),
      prompt: Color(0xFF002F6C),
      keyword: Color(0xFF6B21A8),
      string: Color(0xFF7C2D12),
      comment: Color(0xFF475569),
      error: Color(0xFF991B1B),
    ),
    activityThemeColors: const ActivityThemeColors(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );

  static ThemeData get tritanopiaTheme => _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFDF6F6),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      secondary: Color(0xFF7C2D12),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF18181B),
      error: Color(0xFF991B1B),
      onError: Colors.white,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Colors.white,
      lessonCardBorder: Color(0xFFD32F2F),
      mutedText: Color(0xFF3F3F46),
      readingCard: Color(0xFFFFF3ED),
      knowledgeCapsule: Color(0xFFFFF7ED),
      progressTrack: Color(0xFFFED7AA),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Color(0xFFFAFAFA),
      border: Color(0xFFD32F2F),
      text: Color(0xFF18181B),
      prompt: Color(0xFFD32F2F),
      keyword: Color(0xFF7C2D12),
      string: Color(0xFF7F1D1D),
      comment: Color(0xFF52525B),
      error: Color(0xFF991B1B),
    ),
    activityThemeColors: const ActivityThemeColors(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );
  // 6. TEMA ACROMATOPSIA (Escala de grises estricta / Contraste radical)
  static ThemeData get achromatopsiaTheme => _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Color(0xFFE0E0E0),
      onSecondary: Colors.black,
      surface: Color(0xFF333333),
      onSurface: Colors.white,
      error: Colors.white,
      onError: Colors.black,
    ),
    courseTheme: const CourseTheme(
      lessonCard: Color(0xFF333333),
      lessonCardBorder: Colors.white,
      mutedText: Color(0xFFE0E0E0),
      readingCard: Color(0xFF333333),
      knowledgeCapsule: Color(0xFF1E1E1E),
      progressTrack: Color(0xFF757575),
    ),
    codeConsoleTheme: const CodeConsoleTheme(
      background: Colors.black,
      border: Colors.white,
      text: Colors.white,
      prompt: Colors.white,
      keyword: Colors.white,
      string: Color(0xFFE0E0E0),
      comment: Color(0xFFBDBDBD),
      error: Colors.white,
    ),
    activityThemeColors: const ActivityThemeColors(
      background: Color(0xFFF8FBFF),
      border: Color(0xFFE3ECF7),
      iconBackground: Color(0xFFE8F1FF),
      textTitle: Color(0xFF263238),
      textSubtitle: Color(0xFF607D8B),
      successBackground: Color(0xFFE8F5E9),
      successBorder: Color(0xFF66BB6A),
      successText: Color(0xFF2E7D32),
      actionBackground: Color(0xFFE3F2FD),
      actionBorder: Color(0xFF90CAF9),
      actionText: Color(0xFF1565C0),
    ),
  );

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
        color: Colors.white,//color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        shadowColor: const Color(0x14000000), //FALTAN blurRadius: 6, offset: Offset(0, 2),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary.withValues(alpha: 0.5)
              : null;
        }),
      ),
      extensions: [courseTheme, codeConsoleTheme, activityThemeColors],
    );
  }
}

/// Colores de los contenedores y elementos (Container + BoxDecoration) propios del curso.
class CourseTheme extends ThemeExtension<CourseTheme> {
  const CourseTheme({
    required this.lessonCard,
    required this.lessonCardBorder,
    required this.mutedText,
    required this.readingCard,
    required this.knowledgeCapsule,
    required this.progressTrack,
  });

  final Color lessonCard;
  final Color lessonCardBorder;
  final Color mutedText;
  final Color readingCard;
  final Color knowledgeCapsule;
  final Color progressTrack;

  @override
  CourseTheme copyWith({
    Color? lessonCard,
    Color? lessonCardBorder,
    Color? mutedText,
    Color? readingCard,
    Color? knowledgeCapsule,
    Color? progressTrack,
  }) => CourseTheme(
    lessonCard: lessonCard ?? this.lessonCard,
    lessonCardBorder: lessonCardBorder ?? this.lessonCardBorder,
    mutedText: mutedText ?? this.mutedText,
    readingCard: readingCard ?? this.readingCard,
    knowledgeCapsule: knowledgeCapsule ?? this.knowledgeCapsule,
    progressTrack: progressTrack ?? this.progressTrack,
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

/// Colores semánticos de la Consola Python/editor Python y del resaltado de sintaxis Python.
class CodeConsoleTheme extends ThemeExtension<CodeConsoleTheme> {
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

  final Color background;
  final Color border;
  final Color text;
  final Color prompt;
  final Color keyword;
  final Color string;
  final Color comment;
  final Color error;

  @override
  CodeConsoleTheme copyWith({
    Color? background,
    Color? border,
    Color? text,
    Color? prompt,
    Color? keyword,
    Color? string,
    Color? comment,
    Color? error,
  }) => CodeConsoleTheme(
    background: background ?? this.background,
    border: border ?? this.border,
    text: text ?? this.text,
    prompt: prompt ?? this.prompt,
    keyword: keyword ?? this.keyword,
    string: string ?? this.string,
    comment: comment ?? this.comment,
    error: error ?? this.error,
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

class ModuleCardThemeColors {
  // Lógica 2 + 2 + 2 + 1 para el fondo
  static Color getBackgroundColor(int moduleId) {
    if (moduleId == 1 || moduleId == 2) {
      return const Color(0xFFE8F7FA); // Módulos 1 y 2 (Celeste claro)
    } else if (moduleId == 3 || moduleId == 4) {
      return const Color(0xFF...); // Reemplaza con el color para 3 y 4
    } else if (moduleId == 5 || moduleId == 6) {
      return const Color(0xFF...); // Reemplaza con el color para 5 y 6
    } else if (moduleId == 7) {
      return const Color(0xFF...); // Reemplaza con el color para el 7
    }
    // Color por defecto por seguridad
    return const Color(0xFFE8F7FA); 
  }

  // Lógica para el color del texto (si es que cambia por módulo)
  static Color getTextColor(int moduleId) {
    if (moduleId == 1 || moduleId == 2) {
      return const Color(0xFF607D8B); // Módulos 1 y 2
    }
    // Añade el resto de condiciones o retorna un solo color si el texto siempre es igual
    return const Color(0xFF607D8B); 
  }
}

class ActivityColors {
  // Colores base de la tarjeta
  static const Color background = Color(0xFFF8FBFF);
  static const Color border = Color(0xFFE3ECF7);
  static const Color iconBackground = Color(0xFFE8F1FF);
  
  // Textos
  static const Color textTitle = Color(0xFF263238);
  static const Color textSubtitle = Color(0xFF607D8B);

  // Estado: Completado (Verdes)
  static const Color successBackground = Color(0xFFE8F5E9);
  static const Color successBorder = Color(0xFF66BB6A);
  static const Color successText = Color(0xFF2E7D32);

  // Estado: Acción / Abrir (Azules)
  static const Color actionBackground = Color(0xFFE3F2FD);
  static const Color actionBorder = Color(0xFF90CAF9);
  static const Color actionText = Color(0xFF1565C0);
}

class ActivityThemeColors extends ThemeExtension<ActivityThemeColors> {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color textTitle;
  final Color textSubtitle;
  final Color successBackground;
  final Color successBorder;
  final Color successText;
  final Color actionBackground;
  final Color actionBorder;
  final Color actionText;

  const ActivityThemeColors({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.textTitle,
    required this.textSubtitle,
    required this.successBackground,
    required this.successBorder,
    required this.successText,
    required this.actionBackground,
    required this.actionBorder,
    required this.actionText,
  });

  @override
  ActivityThemeColors copyWith({Color? background, /* ... resto de variables ... */}) {
    return ActivityThemeColors(
      background: background ?? this.background,
      border: border,
      iconBackground: iconBackground,
      textTitle: textTitle,
      textSubtitle: textSubtitle,
      successBackground: successBackground,
      successBorder: successBorder,
      successText: successText,
      actionBackground: actionBackground,
      actionBorder: actionBorder,
      actionText: actionText,
    );
  }

  @override
  ActivityThemeColors lerp(ThemeExtension<ActivityThemeColors>? other, double t) {
    if (other is! ActivityThemeColors) return this;
    return ActivityThemeColors(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      iconBackground: Color.lerp(iconBackground, other.iconBackground, t)!,
      textTitle: Color.lerp(textTitle, other.textTitle, t)!,
      textSubtitle: Color.lerp(textSubtitle, other.textSubtitle, t)!,
      successBackground: Color.lerp(successBackground, other.successBackground, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      actionBackground: Color.lerp(actionBackground, other.actionBackground, t)!,
      actionBorder: Color.lerp(actionBorder, other.actionBorder, t)!,
      actionText: Color.lerp(actionText, other.actionText, t)!,
    );
  }
}

/*
PENDIENTES
*/
/*
PARA EL APPBAR GLOBAL header_widget.dart,
DEFINIR UN ESTILO DE TEXTO PARA EL TÍTULO QUE SEA
MÁS GRANDE Y MÁS LEGIBLE, POR EJEMPLO:
titleTextStyle o style: TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 18,
  letterSpacing: 2,
)
*/
