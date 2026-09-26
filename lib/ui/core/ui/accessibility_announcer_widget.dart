import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Envía un anuncio al lector de pantalla del sistema (TalkBack, VoiceOver,
/// NVDA…).
///
/// Se usa cuando algo cambia en la pantalla sin que el foco se mueva: una
/// respuesta acertada, el cambio de página de una lectura, una actividad
/// completada. Sin esto, quien navega por voz no se entera de que algo pasó.
///
/// Centralizarlo en una función evita repetir en cada pantalla la obtención de
/// la vista y la dirección del texto que exige la API actual de Flutter.
void announceForAccessibility(BuildContext context, String message) {
  final text = message.trim();
  if (text.isEmpty) return;

  SemanticsBinding.instance.ensureSemantics();
  SemanticsService.sendAnnouncement(
    View.of(context),
    text,
    Directionality.of(context),
  );
}
