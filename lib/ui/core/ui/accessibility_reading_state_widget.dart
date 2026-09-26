import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'accessibility_announcer_widget.dart';
import 'web_speech_stub_widget.dart'
    if (dart.library.js_interop) 'web_speech_web_widget.dart'
    as web_speech;

final accessibilityReadingState = AccessibilityReadingState();

class ScreenContentExtractor {
  /// Límite de caracteres que se envían al motor de voz de una sola vez.
  static const int maxLength = 2000;

  static String extractFromContext(BuildContext context) {
    final buffer = StringBuffer();
    final seen = <Element>{};

    void visit(Element element) {
      if (!seen.add(element)) return;

      final widget = element.widget;

      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        _appendChunk(buffer, text);
      } else if (widget is TextField) {
        final decoration = widget.decoration;
        _appendChunk(buffer, decoration?.labelText ?? '');
        _appendChunk(buffer, decoration?.hintText ?? '');
      }

      element.visitChildElements(visit);
    }

    Element? rootElement;
    context.visitAncestorElements((element) {
      if (element.widget is Scaffold ||
          element.widget is MaterialApp ||
          element.widget is Navigator ||
          element.widget is WidgetsApp) {
        rootElement = element;
        return false;
      }
      return true;
    });

    final startElement = rootElement ?? (context as Element);
    visit(startElement);

    final text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      return '';
    }

    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  static void _appendChunk(StringBuffer buffer, String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(value);
  }
}

/// En qué punto está la lectura en voz alta.
enum ReadingStatus {
  /// Ni leyendo ni a medias: el botón ofrece «escuchar».
  idle,

  /// Hablando ahora mismo.
  speaking,

  /// A medias y esperando: `resume()` sigue por donde iba.
  paused,
}

/// Controla la lectura en voz alta de una pantalla.
///
/// Antes esto acompañaba la voz con una franja inferior amarilla que iba
/// resaltando la palabra hablada. Esa franja se retiró a petición expresa, así
/// que aquí ya solo queda la voz.
///
/// Pausar y reanudar se resuelve distinto en cada sitio, y conviene saberlo:
///
/// - En web el navegador pausa y reanuda por su cuenta, y recuerda él por
///   dónde iba. No hay que llevar ninguna cuenta.
/// - En móvil no existe «reanudar»: el motor solo sabe empezar a hablar. Lo
///   que se hace es apuntar por qué carácter va la voz —el motor lo va
///   diciendo— y, al reanudar, mandarle a leer el texto desde ahí. El efecto
///   para quien escucha es el mismo.
class AccessibilityReadingState {
  final ValueNotifier<String?> currentText = ValueNotifier<String?>(null);

  /// En qué punto está la lectura. Es lo que miran los botones para saber si
  /// ofrecer «escuchar», «pausar» o «reanudar».
  final ValueNotifier<ReadingStatus> status = ValueNotifier<ReadingStatus>(
    ReadingStatus.idle,
  );

  /// Si hay una lectura en marcha o a medias.
  ///
  /// Conserva el nombre de cuando además resaltaba texto. Se mantiene porque
  /// hay pantallas que solo necesitan saber «hay algo sonando o no»; quien
  /// necesite distinguir pausa de parada mira [status].
  final ValueNotifier<bool> isHighlighting = ValueNotifier<bool>(false);

  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;
  Timer? _fallbackTimer;

  /// Por qué carácter del texto va la voz, según lo que informa el motor.
  ///
  /// Es lo que permite reanudar en móvil: al volver, se lee desde aquí.
  int _spokenUpTo = 0;

  /// Desde qué carácter se mandó a leer la vez actual.
  ///
  /// El motor cuenta los caracteres del trozo que le diste, no del texto
  /// entero. Al reanudar se le manda un trozo, así que sin sumar esto el
  /// segundo pausado volvería al principio de ese trozo.
  int _offsetBase = 0;

  /// Que el `stop()` de una pausa no se confunda con el de una parada.
  ///
  /// Pausar en móvil obliga a callar el motor, y callarlo dispara el mismo
  /// aviso que una cancelación. Sin esta marca, pausar se contaría como
  /// terminar y se perdería el punto donde iba.
  bool _pausing = false;

  /// Cuándo empezó a sonar el trozo actual y cuánto se calcula que dura.
  /// Solo para web, donde hay que estimar el final. Ver [_scheduleWebReadingEnd].
  DateTime? _webChunkStartedAt;
  Duration _webRemaining = Duration.zero;

  Future<void> initialize() async {
    if (_ttsInitialized || kIsWeb) return;

    try {
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.3); // 0.5 era la velodiad original
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      // Obliga a FlutterTts a esperar que termine el audio antes de resolver el Future de speak()
      await _flutterTts.awaitSpeakCompletion(true);

      // Por dónde va la voz. Es lo único que permite reanudar en móvil: al
      // volver de una pausa se le manda a leer el texto desde este carácter.
      _flutterTts.setProgressHandler((text, start, end, word) {
        _spokenUpTo = _offsetBase + start;
      });

      _flutterTts.setCompletionHandler(_onSpeechFinished);
      _flutterTts.setCancelHandler(_onSpeechCancelled);
      _flutterTts.setErrorHandler((msg) => _onSpeechFinished());
      _ttsInitialized = true;
    } catch (e, st) {
      debugPrint('Error inicializando TTS: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> read(String text, BuildContext context) async {
    final content = text.trim();
    if (content.isEmpty) return;

    await stop();

    currentText.value = content;
    _spokenUpTo = 0;
    _setStatus(ReadingStatus.speaking);

    if (context.mounted) {
      announceForAccessibility(context, content);
    }

    await _speakFrom(0);
  }

  /// Pausa la voz sin perder por dónde iba.
  ///
  /// Sin texto empezado no hace nada: pausar lo que no suena no significa
  /// nada, y dejar el botón en «reanudar» sin nada que reanudar confundiría.
  Future<void> pause() async {
    if (status.value != ReadingStatus.speaking) return;

    if (kIsWeb) {
      _pauseWebCountdown();
      web_speech.pauseBrowserVoice();
    } else {
      // Callar el motor es la única forma de pausar en móvil. La marca evita
      // que ese silencio se cuente como final de la lectura.
      _pausing = true;
      try {
        await _flutterTts.stop();
      } catch (e) {
        debugPrint('Error pausando TTS: $e');
      }
      _pausing = false;
    }

    _setStatus(ReadingStatus.paused);
  }

  /// Sigue leyendo desde donde se pausó.
  Future<void> resume() async {
    if (status.value != ReadingStatus.paused) return;

    final content = currentText.value;
    if (content == null || content.isEmpty) {
      await stop();
      return;
    }

    _setStatus(ReadingStatus.speaking);

    if (kIsWeb) {
      // El navegador guarda él por dónde iba, así que basta con soltarlo.
      web_speech.resumeBrowserVoice();
      _resumeWebCountdown();
      return;
    }

    await _speakFrom(_spokenUpTo);
  }

  /// Pausa o reanuda, según toque. Es lo que usan los botones.
  Future<void> togglePause() async {
    switch (status.value) {
      case ReadingStatus.speaking:
        await pause();
      case ReadingStatus.paused:
        await resume();
      case ReadingStatus.idle:
        break;
    }
  }

  Future<void> _speakFrom(int offset) async {
    final content = currentText.value;
    if (content == null || content.isEmpty) return;

    final safeOffset = offset.clamp(0, content.length);
    if (safeOffset >= content.length) {
      _onSpeechFinished();
      return;
    }

    final pending = content.substring(safeOffset);
    _offsetBase = safeOffset;
    _spokenUpTo = safeOffset;

    if (kIsWeb) {
      web_speech.speakWithBrowserVoice(pending);
      _scheduleWebReadingEnd(pending);
      return;
    }

    try {
      await initialize();
      await _flutterTts.speak(pending);
    } catch (e, st) {
      debugPrint('Error al reproducir TTS: $e');
      debugPrint(st.toString());
      clearHighlight();
    }
  }

  Future<void> stop() async {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;

    if (kIsWeb) {
      web_speech.cancelBrowserVoice();
    } else {
      try {
        await _flutterTts.stop();
      } catch (e) {
        debugPrint('Error deteniendo TTS: $e');
      }
    }

    clearHighlight();
  }

  /// La lectura llegó al final por su cuenta.
  void _onSpeechFinished() {
    _spokenUpTo = 0;
    _offsetBase = 0;
    clearHighlight();
  }

  /// El motor se calló. Si fue por una pausa, no se toca nada: el punto donde
  /// iba es justo lo que hay que conservar.
  void _onSpeechCancelled() {
    if (_pausing) return;
    _onSpeechFinished();
  }

  void _setStatus(ReadingStatus value) {
    status.value = value;
    isHighlighting.value = value != ReadingStatus.idle;
  }

  void clearHighlight() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _webChunkStartedAt = null;
    _webRemaining = Duration.zero;
    _pausing = false;
    _setStatus(ReadingStatus.idle);
  }

  /// Da por terminada la lectura en web pasado el tiempo que se estima que
  /// dura el texto.
  ///
  /// El navegador no avisa de que ha acabado de hablar, así que sin esto la
  /// barra inferior se quedaría ofreciendo «pausar» para siempre. Se calcula a
  /// partir del número de palabras, al mismo ritmo que ya se usaba.
  void _scheduleWebReadingEnd(String content) {
    final words = _splitWords(content);
    if (words.isEmpty) return;

    _startWebCountdown(Duration(milliseconds: 380 * words.length));
  }

  void _startWebCountdown(Duration remaining) {
    _fallbackTimer?.cancel();
    _webRemaining = remaining;
    _webChunkStartedAt = DateTime.now();
    _fallbackTimer = Timer(remaining, _onSpeechFinished);
  }

  /// Congela la cuenta atrás mientras la voz está pausada.
  ///
  /// Sin esto el reloj seguiría corriendo con la voz callada y, al volver, la
  /// pantalla daría la lectura por terminada aunque quedara medio texto.
  void _pauseWebCountdown() {
    final startedAt = _webChunkStartedAt;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;

    if (startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt);
    final left = _webRemaining - elapsed;
    _webRemaining = left.isNegative ? Duration.zero : left;
    _webChunkStartedAt = null;
  }

  void _resumeWebCountdown() {
    if (_webRemaining <= Duration.zero) {
      _onSpeechFinished();
      return;
    }
    _startWebCountdown(_webRemaining);
  }

  static List<String> _splitWords(String content) =>
      content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  void dispose() {
    _fallbackTimer?.cancel();
    currentText.dispose();
    isHighlighting.dispose();
    status.dispose();
  }
}
