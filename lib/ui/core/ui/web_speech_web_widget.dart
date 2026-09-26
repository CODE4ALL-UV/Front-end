import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS()
@staticInterop
class SpeechSynthesisUtterance {
  external factory SpeechSynthesisUtterance(String text);
}

extension SpeechSynthesisUtteranceExtension on SpeechSynthesisUtterance {
  external set lang(String value);
  external set rate(double value);
  external set pitch(double value);
}

@JS()
@staticInterop
class SpeechSynthesis {}

extension SpeechSynthesisExtension on SpeechSynthesis {
  external void cancel();
  external void speak(SpeechSynthesisUtterance utterance);
  external void pause();
  external void resume();
}

@JS('window.speechSynthesis')
external SpeechSynthesis? get speechSynthesis;

bool get isBrowserVoiceAvailable => speechSynthesis != null;

void speakWithBrowserVoice(String text, {String language = 'es-ES'}) {
  try {
    final speech = speechSynthesis;
    if (speech == null) return;

    final utterance = SpeechSynthesisUtterance(text);
    utterance.lang = language;
    utterance.rate = 0.95;
    utterance.pitch = 1.0;

    speech.cancel();
    speech.speak(utterance);
  } catch (e, st) {
    debugPrint('Error usando SpeechSynthesis: $e');
    debugPrint(st.toString());
  }
}

void cancelBrowserVoice() {
  try {
    speechSynthesis?.cancel();
  } catch (e) {
    debugPrint('Error cancelando SpeechSynthesis: $e');
  }
}

/// Deja la voz a mitad, sin perder lo que queda por decir.
///
/// El navegador guarda por su cuenta por dónde iba, así que aquí no hay que
/// llevar la cuenta: `resume()` sigue en la misma palabra. Es la diferencia
/// con `cancel()`, que tira el texto pendiente.
void pauseBrowserVoice() {
  try {
    speechSynthesis?.pause();
  } catch (e) {
    debugPrint('Error pausando SpeechSynthesis: $e');
  }
}

void resumeBrowserVoice() {
  try {
    speechSynthesis?.resume();
  } catch (e) {
    debugPrint('Error reanudando SpeechSynthesis: $e');
  }
}
