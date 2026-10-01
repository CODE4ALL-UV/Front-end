import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/activity_theme.dart';
import 'package:flutter_code4all/ui/core/themes/ide_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900; //OJO: Falta navegador o probar el > 900
  // Todo lo que sea > 900 se considera desktop/pantalla grande
}

/// Atajos rápidos para acceder al tema desde el BuildContext.
/// Acceso: context.colorScheme
///         context.moduleTheme
///         context.codeConsoleTheme
///         context.activityColors
///
/// Si el tema activo no trae alguna extensión —un `Theme` anidado, un diálogo
/// con su propio tema o una prueba con `MaterialApp()` a secas— se usan los
/// colores del tema claro. Con `!` la pantalla entera se rompía.
extension AppThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  ModuleTheme get moduleColors =>
      Theme.of(this).extension<ModuleTheme>() ??
      _fallbackTheme.extension<ModuleTheme>()!;
  CodeConsoleTheme get codeConsoleTheme =>
      Theme.of(this).extension<CodeConsoleTheme>() ??
      _fallbackTheme.extension<CodeConsoleTheme>()!;
  ActivityTheme get activityColors =>
      Theme.of(this).extension<ActivityTheme>() ??
      _fallbackTheme.extension<ActivityTheme>()!;
  MessageTheme get messageColors =>
      Theme.of(this).extension<MessageTheme>() ??
      _fallbackTheme.extension<MessageTheme>()!;
}

final ThemeData _fallbackTheme = AppTheme.getTheme(mode: AppThemeMode.light);

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
  ActivityTheme → Colores semánticos para información, éxito, advertencia,
  peligro y acciones, incluyendo fondo suave, borde visible y texto oscuro.
  Acceso: Theme.of(context).extension<ActivityTheme>()!
          context.activityColors
  
  ModuleTheme → Colores específicos de las tarjetas y elementos de las lecciones.
  Acceso: Theme.of(context).extension<ModuleTheme>()!
          context.moduleTheme

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

/// Cuentas de contraste (WCAG 2.1) para elegir colores que se puedan leer.
///
/// Los temas son para personas con baja visión o con daltonismo: un color que
/// no contrasta deja fuera justo a quien eligió ese tema. Con esto los colores
/// que se calculan al vuelo —los de cada módulo, por ejemplo— salen legibles
/// sin tener que probar a mano cada combinación.
abstract final class AppContrast {
  /// Mínimo para texto normal.
  static const double text = 4.5;

  /// Mínimo para iconos, bordes y piezas grandes.
  static const double ui = 3.0;

  static const Color _darkText = Color(0xFF1A1A1A);

  /// Relación de contraste entre dos colores, de 1 a 21.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Blanco o casi negro: el que mejor se lea encima de [background].
  static Color onColor(Color background) =>
      ratio(Colors.white, background) >= ratio(_darkText, background)
      ? Colors.white
      : _darkText;

  /// El mismo tono, oscurecido o aclarado lo justo para contrastar [min]
  /// con [background].
  static Color readableOn(Color color, Color background, double min) {
    var hsl = HSLColor.fromColor(color);
    final darken = background.computeLuminance() > 0.18;
    for (var i = 0; i < 50 && ratio(hsl.toColor(), background) < min; i++) {
      final next = hsl.lightness + (darken ? -0.02 : 0.02);
      hsl = hsl.withLightness(next.clamp(0.0, 1.0));
    }
    return hsl.toColor();
  }
}

class AppTheme {
  /// Ensambla un ThemeData completo a partir de los tokens visuales del tema.
  ///
  /// Parámetros:
  /// - brightness → Define la luminosidad base: Brightness.light o Brightness.dark.
  /// - scaffoldBackgroundColor → Color de fondo general de las pantallas.
  /// - colorScheme → Colores generales de Material 3 y base cromática de los componentes.
  /// - codeConsoleTheme → Colores específicos de la consola/editor de Python.
  /// - activityTheme → Colores de cada tipo de actividad.
  /// - messageTheme → Colores semánticos para info, success, warning y danger.
  ///
  /// Los colores de cada módulo (ModuleTheme) no se pasan: se calculan a
  /// partir del módulo activo y del modo, en ModuleTheme.fromModule.
  ///
  /// Ningún texto lleva un color fijo: todos salen del colorScheme. Un negro
  /// fijo se ve bien en el tema claro y desaparece en el oscuro.
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required ColorScheme colorScheme,
    required CodeConsoleTheme codeConsoleTheme,
    required ActivityTheme activityTheme,
    required MessageTheme messageTheme,
    required AppThemeMode themeMode,
    required int currentModuleId,
  }) {
    final baseTheme = ThemeData(useMaterial3: true, brightness: brightness);
    final baseTextTheme = baseTheme.textTheme;
    // Generación dinámica de ModuleTheme pasando el módulo y el modo activo
    final moduleTheme = ModuleTheme.fromModule(currentModuleId, themeMode);

    // En el tema oscuro el color principal es el gris de la barra superior:
    // como color de texto o de casilla marcada no se vería sobre el fondo.
    // Ahí los componentes que pintan sobre la superficie usan el secundario.
    final accent =
        AppContrast.ratio(colorScheme.primary, colorScheme.surface) >=
            AppContrast.text
        ? colorScheme.primary
        : colorScheme.secondary;
    final onAccent = accent == colorScheme.primary
        ? colorScheme.onPrimary
        : colorScheme.onSecondary;

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
            bodyMedium: baseTextTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            bodySmall: baseTextTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        shadowColor: const Color(0x14000000),
      ),
      splashColor: accent.withValues(alpha: 0.15),
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
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: accent),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
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
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.dialogRadius),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.secondary,
        linearTrackColor: colorScheme.outlineVariant,
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
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected) ? accent : null,
        ),
        checkColor: WidgetStatePropertyAll(onAccent),
      ),
      chipTheme: ChipThemeData(
        selectedColor: accent.withValues(alpha: 0.18),
        checkmarkColor: colorScheme.onSurface,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
      ),
      listTileTheme: ListTileThemeData(
        selectedColor: accent,
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.78),
        indicatorColor: colorScheme.onPrimary,
        dividerColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      extensions: [moduleTheme, codeConsoleTheme, activityTheme, messageTheme],
    );
  }

  static ThemeData getTheme({required AppThemeMode mode, int moduleId = 6}) {
    switch (mode) {
      case AppThemeMode.light:
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFC62828), // Rojo Univalle
            onPrimary: Colors.white,
            // Azul Python oscuro: el claro (4B8BBE) no llegaba a 4,5:1 y es
            // el color de los botones de texto.
            secondary: Color(0xFF306998),
            onSecondary: Colors.white,
            tertiary: Color(0xFFFFD43B), // Amarillo Python
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF212121),
            onSurfaceVariant: Color(0xFF4F4F4F),
            outline: Color(0xFF757575),
            outlineVariant: Color(0xFFE0E0E0),
            error: Color(0xFFD32F2F),
            onError: Colors.white,
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(0xFFB31D28),
            string: Color(0xFF032F62),
            comment: Color(0xFF5F6670),
            error: Color(0xFFC62828),
          ),
          // Fondo suave y texto oscuro del mismo tono: el texto siempre
          // contrasta con su fondo y también suelto sobre blanco.
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFFE3F2FD),
            infoForeground: Color(0xFF1565C0),
            successBackground: Color(0xFFE8F5E9),
            successForeground: Color(0xFF1B5E20),
            warningBackground: Color(0xFFFFF3E0),
            warningForeground: Color(0xFF8A5000),
            dangerBackground: Color(0xFFFFEBEE),
            dangerForeground: Color(0xFFC62828),
          ),
          activityTheme: const ActivityTheme(
            readingBackground: Color(0xFFF8F8FF),
            readingForeground: Color(0xFF382983),
            nuggetBackground: Color(0xFFFFFFF0),
            nuggetForeground: Color(0xFF4A7A0C),
            exampleBackground: Color(0xFFFFFAF0),
            exampleForeground: Color(0xFF8A5A00),
            exerciseBackground: Color(0xFFF0F8FF),
            exerciseForeground: Color(0xFF6A00D4),
            videoBackground: Color(0xFFFFF0F5),
            videoForeground: Color(0xFFA11C55),
            quizBackground: Color(0xFFFAF0E6),
            quizForeground: Color(0xFF591F0B),
            labBackground: Color(0xFFF5FFFA),
            labForeground: Color(0xFF00796B),
            finalEvaluationBackground: Color(0xFFFFF5EE),
            finalEvaluationForeground: Color(0xFFB34000),
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
            tertiary: Color(0xFFFFD43B), // Amarillo Python
            onTertiary: Color(0xFF212121),
            surface: Color(0xFF1E1E1E),
            onSurface: Color(0xFFF1F1F1),
            onSurfaceVariant: Color(0xFFBDBDBD),
            outline: Color(0xFF8A8A8A),
            outlineVariant: Color(0xFF3A3A3A),
            error: Color(0xFFEF9A9A),
            onError: Color(0xFF601410),
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
            comment: Color(0xFF90A4AE),
            error: Color(0xFFEF5350),
          ),
          // En oscuro el fondo es una tinta apagada y el texto el tono claro.
          // Al revés —cajas claras sobre fondo negro— deslumbra.
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFF0D2840),
            infoForeground: Color(0xFF90CAF9),
            successBackground: Color(0xFF103018),
            successForeground: Color(0xFFA5D6A7),
            warningBackground: Color(0xFF3A2A12),
            warningForeground: Color(0xFFFFCC80),
            dangerBackground: Color(0xFF3B1314),
            dangerForeground: Color(0xFFEF9A9A),
          ),
          activityTheme: const ActivityTheme(
            readingBackground: Color(0xFF221C38),
            readingForeground: Color(0xFFB39DDB),
            nuggetBackground: Color(0xFF22301A),
            nuggetForeground: Color(0xFFC5E1A5),
            exampleBackground: Color(0xFF332A12),
            exampleForeground: Color(0xFFFFE082),
            exerciseBackground: Color(0xFF2E1A33),
            exerciseForeground: Color(0xFFCE93D8),
            videoBackground: Color(0xFF361A26),
            videoForeground: Color(0xFFF48FB1),
            quizBackground: Color(0xFF2E2522),
            quizForeground: Color(0xFFD7CCC8),
            labBackground: Color(0xFF12302D),
            labForeground: Color(0xFF80CBC4),
            finalEvaluationBackground: Color(0xFF3A2217),
            finalEvaluationForeground: Color(0xFFFFAB91),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.achromatopsia:
        // Escala de grises de verdad: ni un solo tono. Los avisos y las
        // actividades se distinguen por su icono y su texto, no por el color.
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF212121),
            onPrimary: Colors.white,
            secondary: Color(0xFF424242),
            onSecondary: Colors.white,
            tertiary: Color(0xFFE0E0E0),
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF000000),
            onSurfaceVariant: Color(0xFF424242),
            outline: Color(0xFF616161),
            outlineVariant: Color(0xFFBDBDBD),
            error: Color(0xFF000000),
            onError: Colors.white,
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF5F5F5),
            border: Color(0xFF9E9E9E),
            text: Color(0xFF212121),
            prompt: Color(0xFF424242),
            keyword: Color(0xFF000000), // Negro fuerte para destacar
            string: Color(0xFF545454),
            comment: Color(0xFF616161),
            error: Color(
              0xFF000000,
            ), // En escala de grises, el error es negro puro
          ),
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFFF5F5F5),
            infoForeground: Color(0xFF212121),
            successBackground: Color(0xFFEEEEEE),
            successForeground: Color(0xFF1A1A1A),
            warningBackground: Color(0xFFE0E0E0),
            warningForeground: Color(0xFF000000),
            dangerBackground: Color(
              0xFFD6D6D6,
            ), // Fondo más oscuro para alerta máxima
            dangerForeground: Color(0xFF000000),
          ),
          activityTheme: const ActivityTheme(
            readingBackground: Color(0xFFF5F5F5),
            readingForeground: Color(0xFF212121),
            nuggetBackground: Color(0xFFF2F2F2),
            nuggetForeground: Color(0xFF303030),
            exampleBackground: Color(0xFFEFEFEF),
            exampleForeground: Color(0xFF3A3A3A),
            exerciseBackground: Color(0xFFF5F5F5),
            exerciseForeground: Color(0xFF424242),
            videoBackground: Color(0xFFEEEEEE),
            videoForeground: Color(0xFF2B2B2B),
            quizBackground: Color(0xFFF0F0F0),
            quizForeground: Color(0xFF353535),
            labBackground: Color(0xFFF2F2F2),
            labForeground: Color(0xFF404040),
            finalEvaluationBackground: Color(0xFFE8E8E8),
            finalEvaluationForeground: Color(0xFF000000),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.deuteranopia:
        // Sin verde: azules, naranjas y amarillos, que sí se distinguen.
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0D47A1), // Azul profundo accesible
            onPrimary: Colors.white,
            secondary: Color(0xFFB45309), // Ámbar oscuro, legible como texto
            onSecondary: Colors.white,
            tertiary: Color(0xFFFFD43B), // Amarillo Python
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF0D1B2A),
            onSurfaceVariant: Color(0xFF3D4A5C),
            outline: Color(0xFF6B7785),
            outlineVariant: Color(0xFFDCE3EC),
            error: Color(0xFFB71C1C),
            onError: Colors.white,
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(0xFFB34700), // Rojo -> Naranja oscuro
            string: Color(0xFF032F62),
            comment: Color(0xFF5F6670),
            error: Color(0xFFBF360C), // Rojo -> Naranja quemado muy oscuro
          ),
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFFE3F2FD),
            infoForeground: Color(0xFF0D47A1),
            successBackground: Color(0xFFE0F7FA), // Verde -> Cian claro
            successForeground: Color(0xFF00607A), // Cian oscuro
            warningBackground: Color(0xFFFFF8E1),
            warningForeground: Color(0xFF7A5200),
            dangerBackground: Color(0xFFFFEDE1),
            dangerForeground: Color(0xFFA33B00),
          ),
          activityTheme: _colorBlindActivities,
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.protanopia:
        // Sin rojo: azul profundo y dorado oscuro.
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F6F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF005B96), // Azul seguro
            onPrimary: Colors.white,
            // Dorado oscuro: el ámbar brillante (FFC107) escrito sobre
            // blanco no se leía (1,6:1).
            secondary: Color(0xFF7A5C00),
            onSecondary: Colors.white,
            tertiary: Color(0xFFFFD43B), // Amarillo Python
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF1A252C),
            onSurfaceVariant: Color(0xFF3D4A55),
            outline: Color(0xFF6B7785),
            outlineVariant: Color(0xFFDCE3EC),
            error: Color(0xFF8D021F),
            onError: Colors.white,
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFF8FBFF),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF3776AB),
            keyword: Color(0xFF7A5C00), // Rojo -> Dorado oscuro
            string: Color(0xFF032F62),
            comment: Color(0xFF5F6670),
            error: Color(0xFF8E24AA), // Rojo oscuro -> Púrpura/Magenta fuerte
          ),
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFFE3F2FD),
            infoForeground: Color(0xFF005B96),
            successBackground: Color(
              0xFFE0F2F1,
            ), // Verde -> Teal (verde-azulado)
            successForeground: Color(0xFF00695C),
            warningBackground: Color(0xFFFFF8E1),
            warningForeground: Color(0xFF7A5C00),
            dangerBackground: Color(0xFFF3E5F5), // Rojo -> Púrpura claro
            dangerForeground: Color(0xFF6A1B9A),
          ),
          activityTheme: _colorBlindActivities,
          themeMode: mode,
          currentModuleId: moduleId,
        );

      case AppThemeMode.tritanopia:
        // Sin azul ni amarillo: rosas, rojos y verdes azulados.
        return _buildTheme(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFDF7F9),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF880E4F), // Rosa/Magenta profundo
            onPrimary: Colors.white,
            secondary: Color(0xFF00727C), // Cian oscuro accesible
            onSecondary: Colors.white,
            tertiary: Color(0xFFF48FB1), // Amarillo -> Rosa
            onTertiary: Color(0xFF212121),
            surface: Colors.white,
            onSurface: Color(0xFF2C001E),
            onSurfaceVariant: Color(0xFF5A3D4C),
            outline: Color(0xFF7D6470),
            outlineVariant: Color(0xFFEBDDE3),
            error: Color(0xFFC62828),
            onError: Colors.white,
          ),
          codeConsoleTheme: const CodeConsoleTheme(
            background: Color(0xFFFAFAFA),
            border: Color(0xFFB0BEC5),
            text: Color(0xFF263238),
            prompt: Color(0xFF00695C), // Azul -> Teal
            keyword: Color(0xFFC62828), // Rojo (Se mantiene, lo ven bien)
            string: Color(0xFFAD1457), // Azul oscuro -> Rosa oscuro
            comment: Color(0xFF6E6E6E),
            error: Color(0xFFB71C1C), // Rojo muy oscuro
          ),
          messageTheme: const MessageTheme(
            infoBackground: Color(0xFFE0F2F1), // Azul -> Teal claro
            infoForeground: Color(0xFF00695C),
            successBackground: Color(0xFFE8F5E9),
            successForeground: Color(0xFF1B5E20),
            warningBackground: Color(
              0xFFFCE4EC,
            ), // Amarillo/Naranja -> Rosa pálido
            warningForeground: Color(0xFFAD1457),
            dangerBackground: Color(0xFFFFEBEE),
            dangerForeground: Color(0xFFB71C1C),
          ),
          activityTheme: const ActivityTheme(
            readingBackground: Color(0xFFE0F2F1),
            readingForeground: Color(0xFF00695C),
            nuggetBackground: Color(0xFFF1F8E9),
            nuggetForeground: Color(0xFF33691E),
            exampleBackground: Color(0xFFFCE4EC),
            exampleForeground: Color(0xFFAD1457),
            exerciseBackground: Color(0xFFF3E5F5),
            exerciseForeground: Color(0xFF6A1B9A),
            videoBackground: Color(0xFFFFEBEE),
            videoForeground: Color(0xFFC62828),
            quizBackground: Color(0xFFEFEBE9),
            quizForeground: Color(0xFF5D4037),
            labBackground: Color(0xFFE0F2F1),
            labForeground: Color(0xFF00796B),
            finalEvaluationBackground: Color(0xFFFBE9E7),
            finalEvaluationForeground: Color(0xFFB71C1C),
          ),
          themeMode: mode,
          currentModuleId: moduleId,
        );
    }
  }

  /// Actividades para protanopía y deuteranopía: las dos confunden rojo y
  /// verde, así que se apoyan en azules, morados, ocres y marrones.
  static const ActivityTheme _colorBlindActivities = ActivityTheme(
    readingBackground: Color(0xFFE8EAF6),
    readingForeground: Color(0xFF1A237E),
    nuggetBackground: Color(0xFFFFFDE7),
    nuggetForeground: Color(0xFF5D4A00),
    exampleBackground: Color(0xFFFFF3E0),
    exampleForeground: Color(0xFF8A4B00),
    exerciseBackground: Color(0xFFF3E5F5),
    exerciseForeground: Color(0xFF4A148C),
    videoBackground: Color(0xFFFCE4EC),
    videoForeground: Color(0xFF880E4F),
    quizBackground: Color(0xFFEFEBE9),
    quizForeground: Color(0xFF4E342E),
    labBackground: Color(0xFFE1F5FE),
    labForeground: Color(0xFF01579B),
    finalEvaluationBackground: Color(0xFFFBE9E7),
    finalEvaluationForeground: Color(0xFFA33B00),
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
