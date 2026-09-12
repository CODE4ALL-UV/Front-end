import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';

/// Paleta de la ruta de aprendizaje, en versión clara y oscura.
///
/// Todos los pares texto/fondo de esta paleta superan la relación de contraste
/// 4.5:1 que exige WCAG 2.1 nivel AA para texto normal, y los títulos superan
/// 7:1 (nivel AAA). Ningún estado se comunica solo con color: siempre hay
/// además un icono y una etiqueta de texto, para que sea legible también con
/// daltonismo.
@immutable
class SectionPalette {
  const SectionPalette._({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.codeBackground,
    required this.codeText,
    required this.codeBorder,
    required this.appBar,
  });

  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;

  final Color accent;
  final Color accentSoft;
  final Color onAccent;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;

  final Color codeBackground;
  final Color codeText;
  final Color codeBorder;

  final Color appBar;

  static const SectionPalette light = SectionPalette._(
    isDark: false,
    background: Color(0xFFF4F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF4FC),
    border: Color(0xFFD2DEEC),
    textPrimary: Color(0xFF10243B),
    textSecondary: Color(0xFF44607C),
    accent: Color(0xFF0B5FC2),
    accentSoft: Color(0xFFE2EEFC),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1B6B3A),
    successSoft: Color(0xFFE1F3E8),
    warning: Color(0xFF87500A),
    warningSoft: Color(0xFFFCF0DC),
    danger: Color(0xFFA92419),
    dangerSoft: Color(0xFFFBE7E4),
    codeBackground: Color(0xFFECF1F8),
    codeText: Color(0xFF0E2438),
    codeBorder: Color(0xFFCBD9EA),
    appBar: Color(0xFFC62828),
  );

  static const SectionPalette dark = SectionPalette._(
    isDark: true,
    background: Color(0xFF0F1418),
    surface: Color(0xFF1A2128),
    surfaceAlt: Color(0xFF222B33),
    border: Color(0xFF3A4650),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFB7C4D0),
    accent: Color(0xFF84B8F7),
    accentSoft: Color(0xFF17314C),
    onAccent: Color(0xFF06182B),
    success: Color(0xFF82D9A2),
    successSoft: Color(0xFF12331F),
    warning: Color(0xFFF3C877),
    warningSoft: Color(0xFF3A2B10),
    danger: Color(0xFFF3ABA4),
    dangerSoft: Color(0xFF3D1B17),
    codeBackground: Color(0xFF0B1117),
    codeText: Color(0xFFE6EDF3),
    codeBorder: Color(0xFF31404D),
    appBar: Color(0xFF262B30),
  );

  static SectionPalette of(BuildContext context) =>
      VisualThemeController.resolveIsDark(context) ? dark : light;

  /// Color de acento y su fondo suave según la intención del bloque.
  ({Color foreground, Color background}) tone(SectionTone tone) =>
      switch (tone) {
        SectionTone.info => (foreground: accent, background: accentSoft),
        SectionTone.success => (foreground: success, background: successSoft),
        SectionTone.warning => (foreground: warning, background: warningSoft),
        SectionTone.danger => (foreground: danger, background: dangerSoft),
      };
}

enum SectionTone { info, success, warning, danger }

/// Medidas compartidas por toda la ruta de aprendizaje.
abstract final class SectionMetrics {
  /// Tamaño mínimo de cualquier elemento pulsable.
  ///
  /// 48 dp es el mínimo que recomiendan tanto Material como WCAG 2.1 para que
  /// una persona con motricidad reducida pueda acertar sin esfuerzo.
  static const double minTapTarget = 48;

  static const double cardRadius = 16;
  static const double pillRadius = 999;
  static const double gap = 12;
  static const double sectionGap = 20;

  /// Ancho máximo de una columna de texto.
  ///
  /// Más allá de ~720 px el ojo pierde el renglón al saltar de línea, así que
  /// en pantallas anchas el contenido se centra en lugar de estirarse.
  static const double maxContentWidth = 720;

  static EdgeInsets pagePadding(double width) =>
      EdgeInsets.symmetric(horizontal: width < 380 ? 14 : 20, vertical: 18);
}
