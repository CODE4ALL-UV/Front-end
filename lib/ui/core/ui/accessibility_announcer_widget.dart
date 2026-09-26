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

  // ensureSemantics() entrega un permiso que hay que devolver. Antes se
  // descartaba, así que cada anuncio dejaba el árbol de semántica encendido
  // para siempre; y esta aplicación anuncia en cada respuesta acertada, cada
  // cambio de página y cada lectura en voz alta. El mensaje ya sale hacia el
  // sistema en sendAnnouncement, de modo que el permiso se puede devolver
  // acto seguido.
  final semantics = SemanticsBinding.instance.ensureSemantics();
  try {
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    );
  } finally {
    semantics.dispose();
  }
}
