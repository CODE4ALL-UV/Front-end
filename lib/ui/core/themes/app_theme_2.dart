import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Constructor privado para evitar instancias accidentales

  // 1. CONFIGURACIÓN DEL TEMA CLARO COMPLETO
  // (Sigue igual, pero ahora puedes llamar a tus mapas desde aquí)
  static ThemeData get lightTheme {
    // Tomamos la base tipográfica oficial de Material 3 para el modo claro
    final baseTextTheme = ThemeData.light(useMaterial3: true).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Contrastes claros u oscuros
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), //Fondo de pantalla
      // 1.1. SISTEMA TIPOGRÁFICO GLOBAL (TextTheme - Modifica los textos)
      // ver: TextTheme class (https://api.flutter.dev/flutter/material/TextTheme-class.html)
      textTheme: TextTheme(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF212121),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF212121),
          fontStyle: FontStyle.normal,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF757575),
          fontStyle: FontStyle.italic,
        ),
      ),
      fontFamily: 'Roboto',
      // 1.2. PALETA DE COLORES GLOBAL (Sistema Semántico Basado en Material Design 3)
      colorScheme: const ColorScheme.light(
        primary: Color(
          0xFFE53935,
        ), // Color principal de la marca (Rojo Univalle)
        onPrimary: Color(
          0xFFFFFFFF,
        ), // Color del texto/iconos que van SOBRE el color primary
        secondary: Color(
          0xFF5C6BC0,
        ), // Color secundario (usado para destacar elementos visuales)
        onSecondary: Color(
          0xFFFFFFFF,
        ), // Color del texto/iconos SOBRE el color secondary
        surface: Color(
          0xFFFFFFFF,
        ), // Color de fondo de componentes intermedios (Tarjetas, Navbars)
        onSurface: Color(
          0xFF212121,
        ), // Color del texto/iconos que van SOBRE las superficies (Negro/Gris)
        error: Color(
          0xFFD32F2F,
        ), // Color para estados de error (Validaciones fallidas)
        onError: Color(
          0xFFFFFFFF,
        ), // Color del texto/iconos SOBRE estados de error
      ),

      // 1.3. ESTILOS DE LOS COMPONENTES DE LA INTERFAZ (Overrides)
      // 1.3.1. Header
      appBarTheme: const AppBarThemeData(
        backgroundColor: Color(0xFFE53935), // Color de fondo
        foregroundColor: Color(0xFFFFFFFF), // Color de iconos y texto
        elevation: 0, // Altura de la sombra
        centerTitle: true, // Fuerza que el título siempre esté centrado
        //titleTextStyle: _headerTextStyle, // Aplica estilo de texto del header
        // Tamaño del icono por defecto
        actionsIconTheme: IconThemeData(size: 28.0),
      ),

      // 1.3.2. Footer
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFFE53935),
        unselectedItemColor: Color(0xFF757575),
        elevation: 8,
        //selectedLabelStyle: _footerTextStyle,
        //unselectedLabelStyle: _footerTextStyle,
        selectedIconTheme: IconThemeData(size: 28.0),
        unselectedIconTheme: IconThemeData(size: 24.0),
      ),

      // 1.3.3. Tarjetas (Cards)
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // 1.4. ENTORNO INTERACTIVO Y ESTADOS DE CLIC (Respuestas Visuales)
      // 1.4.1. Efecto "ola" al hacer clic
      splashColor: const Color(0xFFE53935).withValues(alpha: 0.15),
      // 1.4.2. Color de selección fija al mantener presionado
      highlightColor: Colors.transparent,
      // 1.4.3. Botones Flotantes (Floating Action Buttons - Como el de accesibilidad)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      // 1.4.4. Botones Elevados (ElevatedButtons): Ideales para enviar formularios
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFFE53935,
              ), // Color de fondo por defecto
              foregroundColor: Colors.white, // Color del texto interno
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ).copyWith(
              // CONTROL DE ESTADOS AVANZADOS (Equivalente a onClicked / Disabled de la Web)
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                states,
              ) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors
                      .grey[300]; // Color si el botón está DESHABILITADO (ej. formulario incompleto)
                }
                if (states.contains(WidgetState.pressed)) {
                  return const Color(
                    0xB3E53935,
                  ); // Color si el usuario está haciendo CLIC en el celular
                }
                return null; // Usa el color por defecto si está en estado normal
              }),
            ),
      ),

      // 1.4.5. CAMPOS DE TEXTO (InputDecorationTheme - Crucial para tus custom_textfields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(
          0xFFEEEEEE,
        ), // Fondo gris suave de la caja de texto
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // Borde en estado normal
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        // Borde cuando el usuario hace clic para escribir (Equivalente a :focus de la Web)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2.0),
        ),
        // Borde cuando hay un error de validación de contraseña/correo
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
      ),

      // 1.5. Estilos globales para los iconos del cuerpo de la aplicación
      iconTheme: const IconThemeData(
        // Color por defecto para iconos en el Scaffold
        color: Color(0xFF212121),
        // Tamaño estándar móvil por defecto
        size: 24.0,
      ),

      // 1.6. COMPONENTES EXTRA PARA EL CONTROL DEL BODY
      // 1.6.1. Botones de Texto (TextButton): Ideales para "Olvidé mi contraseña" o "Registrarse"
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(
            0xFF5C6BC0,
          ), // Color del texto interactivo (Azul/Morado)
          //textStyle: _footerTextStyle, // Hereda tus 14px centralizados
        ),
      ),

      // 1.6.2. Botones con Contorno (OutlinedButton): Ideales para botones secundarios como "Cancelar"
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE53935), // Texto rojo
          side: const BorderSide(
            color: Color(0xFFE53935),
            width: 1.5,
          ), // Borde rojo
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // 1.6.3. Diálogos de Alerta (AlertDialog): Crucial para avisos de error o confirmaciones
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 6,
        titleTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF757575),
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF757575),
          fontStyle: FontStyle.italic,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),

      // 1.6.4. Indicadores de Carga (ProgressIndicator): Para cuando la app se conecta a la API
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFE53935), // El círculo de carga girará en Rojo Univalle
        //refreshIndicatorColor: Color(0xFF5C6BC0),
      ),

      // 1.6.5. Checkboxes y Switches (Crucial para tu módulo de accesibilidad_adaptacion)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE53935);
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE53935).withValues(alpha: 0.5);
          }
          return null;
        }),
      ),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFFFFFFFF),
          lessonCardBorder: Color(0xFFE3F2FD),
          mutedText: Color(0xFF607D8B),
          readingCard: Color(0xFFEAF7FF),
          knowledgeCapsule: Color(0xFFE8F5E9),
          progressTrack: Color(0xFFE3F2FD),
        ),
        CodeConsoleTheme(
          background: Color(0xFFF8FBFF),
          border: Color(0xFFB0BEC5),
          text: Color(0xFF263238),
          prompt: Color(0xFF1E88E5),
          keyword: Color(0xFFD73A49),
          string: Color(0xFF032F62),
          comment: Color(0xFF6A737D),
          error: Color(0xFFD32F2F),
        ),
      ],
    );
  }

  // PALETAS EXCLUSIVAS PARA EL RESALTADO DE SINTAXIS PYTHON
  // Estilos del Editor Python para el Modo Claro (Inspirado en GitHub Light accesible)
  static Map<String, TextStyle> get pythonLightSyntax {
    return {
      'keyword': const TextStyle(
        color: Color(0xFFD73A49),
        fontWeight: FontWeight.bold,
      ), // def, if, return
      'string': const TextStyle(
        color: Color(0xFF032F62),
        fontStyle: FontStyle.normal,
      ),
      'comment': const TextStyle(
        color: Color(0xFF6A737D),
        fontStyle: FontStyle.italic,
      ), // # Mi comentario
      'number': const TextStyle(color: Color(0xFF005CC5)), // 10, 3.14
      'title': const TextStyle(
        color: Color(0xFF6F42C1),
        fontWeight: FontWeight.bold,
      ), // Nombre de funciones
    };
  }

  // 2. TEMA OSCURO STANDARD
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF90CAF9),
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFFFFFFF), // Texto sobre Navbar (Blanco)
      ),
      // 1.3. ESTILOS DE LOS COMPONENTES DE LA INTERFAZ (Overrides)
      // 1.3.1. Header
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A2A2A),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0, // Altura de la sombra
        centerTitle: true, // Fuerza que el título siempre esté centrado
        //titleTextStyle: _headerTextStyle, // Aplica estilo de texto del header
        // Tamaño del icono por defecto
        actionsIconTheme: IconThemeData(size: 28.0),
      ),
      //textTheme: const TextTheme(bodyMedium: _footerTextStyle),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFF1E1E1E),
          lessonCardBorder: Color(0xFF334155),
          mutedText: Color(0xFFB0BEC5),
          readingCard: Color(0xFF1B3A4B),
          knowledgeCapsule: Color(0xFF1F2D31),
          progressTrack: Color(0xFF263238),
        ),
        CodeConsoleTheme(
          background: Color(0xFF1F2937),
          border: Color(0xFF334155),
          text: Color(0xFFF8FAFC),
          prompt: Color(0xFF80DEEA),
          keyword: Color(0xFF90CAF9),
          string: Color(0xFFE0C97D),
          comment: Color(0xFF94A3B8),
          error: Color(0xFFEF9A9A),
        ),
      ],
    );
  }

  // 3. TEMA PROTANOPÍA (Sin Rojo)
  static ThemeData get protanopiaTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0055B7), // Azul fuerte seguro
        surface: Color(0xFFFFDD00), // Amarillo de alto contraste
        onSurface: Color(0xFF000000),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0055B7),
        foregroundColor: Color(0xFFFFFFFF),
        //titleTextStyle: _headerTextStyle,
      ),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFFFFFFFF),
          lessonCardBorder: Color(0xFF0055B7),
          mutedText: Color(0xFF374151),
          readingCard: Color(0xFFEAF4FF),
          knowledgeCapsule: Color(0xFFF3F4F6),
          progressTrack: Color(0xFFDCEBFA),
        ),
        CodeConsoleTheme(
          background: Color(0xFFF8FAFC),
          border: Color(0xFF0055B7),
          text: Color(0xFF111827),
          prompt: Color(0xFF0055B7),
          keyword: Color(0xFF5B2C83),
          string: Color(0xFF6B3E00),
          comment: Color(0xFF4B5563),
          error: Color(0xFF7F1D1D),
        ),
      ],
    );
  }

  // 4. TEMA DEUTERANOPÍA (Sin Verde - El más común)
  static ThemeData get deuteranopiaTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF002F6C), // Azul marino profundo
        surface: Color(0xFFEAA100), // Amarillo ocre accesible
        onSurface: Color(0xFF1A1A1A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF002F6C),
        foregroundColor: Color(0xFFFFFFFF),
        //titleTextStyle: _headerTextStyle,
      ),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFFFFFFFF),
          lessonCardBorder: Color(0xFF002F6C),
          mutedText: Color(0xFF334155),
          readingCard: Color(0xFFF7F2E8),
          knowledgeCapsule: Color(0xFFF3F4F6),
          progressTrack: Color(0xFFE6D4A8),
        ),
        CodeConsoleTheme(
          background: Color(0xFFF8FAFC),
          border: Color(0xFF002F6C),
          text: Color(0xFF111827),
          prompt: Color(0xFF002F6C),
          keyword: Color(0xFF6B21A8),
          string: Color(0xFF7C2D12),
          comment: Color(0xFF475569),
          error: Color(0xFF991B1B),
        ),
      ],
    );
  }

  // 5. TEMA TRITANOPÍA (Sin Azul)
  static ThemeData get tritanopiaTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFDF6F6),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD32F2F), // Rojo/Rojo oscuro accesible
        surface: Color(0xFF00838F), // Cian/Turquesa puro
        onSurface: Color(0xFF000000),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Color(0xFFFFFFFF),
        //titleTextStyle: _headerTextStyle,
      ),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFFFFFFFF),
          lessonCardBorder: Color(0xFFD32F2F),
          mutedText: Color(0xFF3F3F46),
          readingCard: Color(0xFFFFF3ED),
          knowledgeCapsule: Color(0xFFFFF7ED),
          progressTrack: Color(0xFFFED7AA),
        ),
        CodeConsoleTheme(
          background: Color(0xFFFAFAFA),
          border: Color(0xFFD32F2F),
          text: Color(0xFF18181B),
          prompt: Color(0xFFD32F2F),
          keyword: Color(0xFF7C2D12),
          string: Color(0xFF7F1D1D),
          comment: Color(0xFF52525B),
          error: Color(0xFF991B1B),
        ),
      ],
    );
  }

  // 6. TEMA ACROMATOPSIA (Escala de grises estricta / Contraste radical)
  static ThemeData get achromatopsiaTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000), // Negro absoluto
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF), // Blanco puro
        surface: Color(0xFF333333), // Gris oscuro
        onSurface: Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        foregroundColor: Color(0xFFFFFFFF),
        /*side: BorderSide(
          color: Color(0xFFFFFFFF),
          width: 1.5,
        ),*/
        // Borde blanco accesible
        //titleTextStyle: _headerTextStyle,
      ),
      extensions: const [
        CourseTheme(
          lessonCard: Color(0xFF333333),
          lessonCardBorder: Color(0xFFFFFFFF),
          mutedText: Color(0xFFE0E0E0),
          readingCard: Color(0xFF333333),
          knowledgeCapsule: Color(0xFF1E1E1E),
          progressTrack: Color(0xFF757575),
        ),
        CodeConsoleTheme(
          background: Color(0xFF000000),
          border: Color(0xFFFFFFFF),
          text: Color(0xFFFFFFFF),
          prompt: Color(0xFFFFFFFF),
          keyword: Color(0xFFFFFFFF),
          string: Color(0xFFE0E0E0),
          comment: Color(0xFFBDBDBD),
          error: Color(0xFFFFFFFF),
        ),
      ],
    );
  }

  // PALETAS EXCLUSIVAS PARA EL RESALTADO DE SINTAXIS PYTHON
  // Estilos de Python para el Modo Acromatopsia (Contraste radical en escala de grises)
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

// Container + BoxDecoration propios del curso
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
  }) {
    return CourseTheme(
      lessonCard: lessonCard ?? this.lessonCard,
      lessonCardBorder: lessonCardBorder ?? this.lessonCardBorder,
      mutedText: mutedText ?? this.mutedText,
      readingCard: readingCard ?? this.readingCard,
      knowledgeCapsule: knowledgeCapsule ?? this.knowledgeCapsule,
      progressTrack: progressTrack ?? this.progressTrack,
    );
  }

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

// Consola/editor Python
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
  }) {
    return CodeConsoleTheme(
      background: background ?? this.background,
      border: border ?? this.border,
      text: text ?? this.text,
      prompt: prompt ?? this.prompt,
      keyword: keyword ?? this.keyword,
      string: string ?? this.string,
      comment: comment ?? this.comment,
      error: error ?? this.error,
    );
  }

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
