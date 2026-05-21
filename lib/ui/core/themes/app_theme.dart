import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Constructor privado para evitar instancias

  // Estilo de texto base para los encabezados (Headers)
  static const TextStyle _headerTextStyle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
  );

  // Estilo de texto base para los pies de página (Footers)
  static const TextStyle _footerTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  // 1. TEMA CLARO STANDARD
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), //TEST IT
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE53935), // Background Rojo UniValle
        surface: Color(0xFFFFFFFF), // Fondo de Navbar/Cards
        onSurface: Color(0xFF212121), // Texto sobre Navbar (Negro)
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2196F3), //El fondo del AppBar original
        foregroundColor: Color(0xFFFFFFFF), //El color de los iconos y texto
        elevation: 0, // Quitamos la sombra como lo tenía tu compañero
        titleTextStyle: TextStyle(
          fontSize: 18.0, // Heredado del código espagueti
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0, // Conservamos el espaciado de letras
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
    );
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFFFFFFF),
        titleTextStyle: _headerTextStyle,
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
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
        titleTextStyle: _headerTextStyle,
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
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
        titleTextStyle: _headerTextStyle,
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
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
        titleTextStyle: _headerTextStyle,
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
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
        titleTextStyle: _headerTextStyle,
      ),
      textTheme: const TextTheme(bodyMedium: _footerTextStyle),
    );
  }
}
