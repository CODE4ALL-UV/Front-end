import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Para qué es lo que se dicta: cambia cómo se limpia lo que se oyó.
enum DictationKind {
  /// Texto libre: se deja tal cual.
  text,

  /// Un correo: «sebastián arroba gmail punto com» → `sebastian@gmail.com`.
  email,

  /// Una contraseña: se quitan los espacios que el reconocedor mete entre
  /// palabras y cifras, y nada más.
  password,
}

/// No se puede dictar: no hay micrófono, se negó el permiso o el navegador no
/// sabe reconocer voz.
class DictationUnavailableException implements Exception {
  DictationUnavailableException(this.message);

  /// Explicación en castellano, lista para decir en voz alta.
  final String message;

  @override
  String toString() => message;
}

/// Escuchar una frase por el micrófono y devolverla como texto.
abstract class VoiceDictation {
  /// Escucha hasta que la persona deja de hablar y devuelve lo entendido, o
  /// null si no se oyó nada. [onPartial] recibe el texto según se va
  /// reconociendo, para enseñarlo en pantalla.
  Future<String?> listen({void Function(String partial)? onPartial});

  /// Deja de escuchar ya; [listen] devuelve lo que se llevara entendido.
  Future<void> stop();

  /// Suena al empezar y al terminar de escuchar.
  ///
  /// Quien no ve no tiene otra forma de saber cuándo puede hablar. Es un
  /// pitido y no una frase porque una frase dicha por el altavoz la
  /// recogería el propio micrófono.
  Future<void> cue({required bool start});

  /// Limpia lo que se oyó según para qué sea.
  static String normalize(String heard, DictationKind kind) {
    final text = heard.trim();
    switch (kind) {
      case DictationKind.text:
        return text;
      case DictationKind.password:
        return text.replaceAll(RegExp(r'\s+'), '');
      case DictationKind.email:
        var email = ' ${_withoutAccents(text.toLowerCase())} ';
        const words = {
          'arroba': '@',
          'guion bajo': '_',
          'barra baja': '_',
          'guion': '-',
          'punto': '.',
        };
        for (final MapEntry(key: word, value: sign) in words.entries) {
          email = email.replaceAll(RegExp('\\s$word\\s'), ' $sign ');
        }
        return email.replaceAll(RegExp(r'\s+'), '');
    }
  }

  static String _withoutAccents(String text) {
    const from = 'áéíóúü';
    const to = 'aeiouu';
    final buffer = StringBuffer();
    for (final char in text.split('')) {
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }
}

/// Dictado con el reconocedor del sistema: el de Android o iOS en el móvil y
/// el del navegador en web.
///
/// **Privacidad.** En Chrome el audio lo reconoce Google en sus servidores, y
/// en muchos móviles también. No se guarda nada en el backend propio, pero sí
/// sale del dispositivo: conviene saberlo antes de dictar una contraseña.
class SpeechToTextDictation implements VoiceDictation {
  SpeechToTextDictation({this.localeId = 'es-CO'});

  /// Español de Colombia. Si el dispositivo no lo tiene, el reconocedor cae
  /// en el español que tenga.
  final String localeId;

  final SpeechToText _speech = SpeechToText();
  final AudioPlayer _player = AudioPlayer();

  Completer<String?>? _pending;
  String _heard = '';
  String? _error;

  /// Errores que significan «no hay micrófono que valga», no «no te oí».
  static const _blockingErrors = {
    'not-allowed',
    'service-not-allowed',
    'audio-capture',
    'error_permission',
    'error_audio_error',
    'not supported',
    'speech_not_supported',
  };

  @override
  Future<String?> listen({void Function(String partial)? onPartial}) async {
    if (_pending != null) await stop();

    final bool ready;
    try {
      ready = await _speech.initialize(onError: _onError, onStatus: _onStatus);
    } catch (e) {
      debugPrint('No se pudo preparar el reconocimiento de voz: $e');
      throw DictationUnavailableException(
        'El reconocimiento de voz no está disponible en este dispositivo.',
      );
    }
    if (!ready) {
      throw DictationUnavailableException(
        'No se puede usar el micrófono. Revisa que la aplicación o el '
        'navegador tengan permiso para usarlo.',
      );
    }

    final pending = _pending = Completer<String?>();
    _heard = '';
    _error = null;

    try {
      await _speech.listen(
        onResult: (result) {
          _heard = result.recognizedWords;
          onPartial?.call(_heard);
          if (result.finalResult) _finish();
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          // Tiempo para pensar antes de empezar y entre palabras, sin dejar
          // el micrófono abierto para siempre si nadie habla.
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 30),
        ),
      );
    } catch (e) {
      debugPrint('No se pudo empezar a escuchar: $e');
      _pending = null;
      throw DictationUnavailableException(
        'No se pudo empezar a escuchar por el micrófono.',
      );
    }

    return pending.future;
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus) _finish();
  }

  void _onError(SpeechRecognitionError error) {
    _error = error.errorMsg;
    if (_blockingErrors.contains(error.errorMsg)) _finish();
  }

  void _finish() {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    _pending = null;

    final heard = _heard.trim();
    if (heard.isEmpty && _blockingErrors.contains(_error)) {
      pending.completeError(
        DictationUnavailableException(
          'No hay permiso para usar el micrófono. Actívalo en el navegador o '
          'en los ajustes del teléfono y vuelve a intentarlo.',
        ),
      );
      return;
    }
    pending.complete(heard.isEmpty ? null : heard);
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('No se pudo parar el reconocimiento de voz: $e');
    }
    // Por si el reconocedor no llega a avisar de que terminó.
    _finish();
  }

  @override
  Future<void> cue({required bool start}) async {
    try {
      await _player.stop();
      await _player.play(
        AssetSource(start ? 'audios/mic_start.wav' : 'audios/mic_end.wav'),
      );
    } catch (e) {
      // Sin pitido se puede dictar igual; la pantalla también lo indica.
      debugPrint('No se pudo reproducir el aviso del micrófono: $e');
    }
  }
}
