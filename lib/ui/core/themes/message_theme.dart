import 'package:flutter/material.dart';

// info: azul
// success: verde
// warning: amarillo
// danger: rojo
enum MessageThemeTone { info, success, warning, danger }

class MessageTheme extends ThemeExtension<MessageTheme> {
  final Color infoBackground;
  final Color infoForeground;
  final Color successBackground;
  final Color successForeground;
  final Color warningBackground;
  final Color warningForeground;
  final Color dangerBackground;
  final Color dangerForeground;

  const MessageTheme({
    required this.infoBackground,
    required this.infoForeground,
    required this.successBackground,
    required this.successForeground,
    required this.warningBackground,
    required this.warningForeground,
    required this.dangerBackground,
    required this.dangerForeground,
  });

  ({Color background, Color foreground}) tone(MessageThemeTone tone) =>
      switch (tone) {
        MessageThemeTone.info => (
          background: infoBackground,
          foreground: infoForeground,
        ),
        MessageThemeTone.success => (
          background: successBackground,
          foreground: successForeground,
        ),
        MessageThemeTone.warning => (
          background: warningBackground,
          foreground: warningForeground,
        ),
        MessageThemeTone.danger => (
          background: dangerBackground,
          foreground: dangerForeground,
        ),
      };

  @override
  MessageTheme copyWith({
    Color? infoBackground,
    Color? infoForeground,
    Color? successBackground,
    Color? successForeground,
    Color? warningBackground,
    Color? warningForeground,
    Color? dangerBackground,
    Color? dangerForeground,
  }) {
    return MessageTheme(
      infoBackground: infoBackground ?? this.infoBackground,
      infoForeground: infoForeground ?? this.infoForeground,
      successBackground: successBackground ?? this.successBackground,
      successForeground: successForeground ?? this.successForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
      dangerBackground: dangerBackground ?? this.dangerBackground,
      dangerForeground: dangerForeground ?? this.dangerForeground,
    );
  }

  @override
  MessageTheme lerp(ThemeExtension<MessageTheme>? other, double t) {
    if (other is! MessageTheme) return this;
    return MessageTheme(
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successForeground: Color.lerp(
        successForeground,
        other.successForeground,
        t,
      )!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
      warningForeground: Color.lerp(
        warningForeground,
        other.warningForeground,
        t,
      )!,
      dangerBackground: Color.lerp(
        dangerBackground,
        other.dangerBackground,
        t,
      )!,
      dangerForeground: Color.lerp(
        dangerForeground,
        other.dangerForeground,
        t,
      )!,
    );
  }
}
