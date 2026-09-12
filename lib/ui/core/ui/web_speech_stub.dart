/// Implementación por defecto (móvil y escritorio).
///
/// En estas plataformas la síntesis de voz la resuelve `flutter_tts`, por lo
/// que aquí no hay nada que hacer. Existe para que `dart:js_interop` sólo se
/// compile en web y la app siga construyéndose en Android, iOS y escritorio.
void speakWithBrowserVoice(String text, {String language = 'es-ES'}) {}

void cancelBrowserVoice() {}

bool get isBrowserVoiceAvailable => false;
