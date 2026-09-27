import 'package:flutter/material.dart';

// info: azul
// success: verde
// warning: amarillo
// danger: rojo
// lectura: azul violeta OK
// capsula: amarillo verde OK (Retroalimentación, Ayudas, Tips, Buenas Prácticas)
// ejemplo: amarillo naranja OK
// ejercicio: violeta OK
// video: rojo violeta OK
// quiz: café OK
// laboratorio: azul verde OK
// evaluacion final: rojo naranja OK
// Omitidos: Glosario, Diccionario de LSC, Diagramas de flujo, Glosario interactivo, Califiaciones
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
  ActivityThemeColors copyWith({
    Color? infoBackground,
    Color? infoBorder,
    Color? infoText,
    Color? successBackground,
    Color? successBorder,
    Color? successText,
    Color? warningBackground,
    Color? warningBorder,
    Color? warningText,
    Color? dangerBackground,
    Color? dangerBorder,
    Color? dangerText,
  }) {
    return ActivityThemeColors(
      infoBackground: infoBackground ?? this.infoBackground,
      infoBorder: infoBorder ?? this.infoBorder,
      infoText: infoText ?? this.infoText,
      successBackground: successBackground ?? this.successBackground,
      successBorder: successBorder ?? this.successBorder,
      successText: successText ?? this.successText,
      warningBackground: warningBackground ?? this.warningBackground,
      warningBorder: warningBorder ?? this.warningBorder,
      warningText: warningText ?? this.warningText,
      dangerBackground: dangerBackground ?? this.dangerBackground,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      dangerText: dangerText ?? this.dangerText,
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
