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

/// Controla la lectura en voz alta de una pantalla.
///
/// Antes esto acompañaba la voz con una franja inferior amarilla que iba
/// resaltando la palabra hablada. Esa franja se retiró a petición expresa, así
/// que aquí ya solo queda la voz.
class AccessibilityReadingState {
  final ValueNotifier<String?> currentText = ValueNotifier<String?>(null);

  /// Si ahora mismo se está leyendo en voz alta.
  ///
  /// Conserva el nombre de cuando además resaltaba texto: es lo que mira la
  /// barra inferior para ofrecer «parar» en lugar de «escuchar».
  final ValueNotifier<bool> isHighlighting = ValueNotifier<bool>(false);

  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;
  Timer? _fallbackTimer;

  Future<void> initialize() async {
    if (_ttsInitialized || kIsWeb) return;

    try {
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.3); // 0.5 era la velodiad original
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      // Obliga a FlutterTts a esperar que termine el audio antes de resolver el Future de speak()
      await _flutterTts.awaitSpeakCompletion(true);
      _flutterTts.setCompletionHandler(clearHighlight);
      _flutterTts.setCancelHandler(clearHighlight);
      _flutterTts.setErrorHandler((msg) => clearHighlight());
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
    isHighlighting.value = true;

    if (context.mounted) {
      announceForAccessibility(context, content);
    }

    if (kIsWeb) {
      web_speech.speakWithBrowserVoice(content);
      _scheduleWebReadingEnd(content);
      return;
    }

    try {
      await initialize();
      await _flutterTts.speak(content);
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

  void clearHighlight() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    isHighlighting.value = false;
  }

  /// Da por terminada la lectura en web pasado el tiempo que se estima que
  /// dura el texto.
  ///
  /// El navegador no avisa de que ha acabado de hablar, así que sin esto la
  /// barra inferior se quedaría ofreciendo «parar» para siempre. Se calcula a
  /// partir del número de palabras, al mismo ritmo que ya se usaba.
  void _scheduleWebReadingEnd(String content) {
    final words = _splitWords(content);
    if (words.isEmpty) return;

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(
      Duration(milliseconds: 380 * words.length),
      clearHighlight,
    );
  }

  static List<String> _splitWords(String content) =>
      content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  void dispose() {
    _fallbackTimer?.cancel();
    currentText.dispose();
    isHighlighting.dispose();
  }
}
