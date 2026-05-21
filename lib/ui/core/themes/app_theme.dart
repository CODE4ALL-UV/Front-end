import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Constructor privado para evitar instancias accidentales

  // 0.1. ESTILOS DE TEXTO BASE (Centralizados para reutilizarse en los bloques)
  // Estilo de texto base para los Headers
  static const TextStyle _headerTextStyle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
  );

  // Estilo de texto base para el Body***
  static const TextStyle _bodyTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  // Estilo de texto base para los Footers
  static const TextStyle _footerTextStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  // 1. CONFIGURACIÓN DEL TEMA CLARO COMPLETO
  static ThemeData get lightTheme {
    return ThemeData(
      // 1.1. SISTEMA TIPOGRÁFICO GLOBAL (TextTheme - Modifica los textos)
      // ver: TextTheme class (https://api.flutter.dev/flutter/material/TextTheme-class.html)
      textTheme: const TextTheme(),
      fontFamily: 'Roboto',
      // 1.2. PALETA DE COLORES GLOBAL (Sistema Semántico Basado en Material Design 3)
      brightness: Brightness.light, // Contrastes claros u oscuros
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), //Fondo de pantalla
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
        titleTextStyle: _headerTextStyle, // Aplica estilo de texto del header
        // Tamaño del icono por defecto
        actionsIconTheme: IconThemeData(size: 28.0),
      ),

      // 1.3.2. Footer
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFFE53935),
        unselectedItemColor: Color(0xFF757575),
        elevation: 8,
        selectedLabelStyle: _footerTextStyle,
        unselectedLabelStyle: _footerTextStyle,
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
          textStyle: _footerTextStyle, // Hereda tus 14px centralizados
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
        titleTextStyle: _headerTextStyle.copyWith(
          color: const Color(0xFF212121),
        ),
        contentTextStyle: _bodyTextStyle.copyWith(
          color: const Color(0xFF757575),
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
