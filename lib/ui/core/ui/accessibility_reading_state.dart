import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'accessibility_announcer.dart';

import 'web_speech_stub.dart'
    if (dart.library.js_interop) 'web_speech_web.dart'
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

/// Controla la lectura en voz alta de una pantalla y el resaltado palabra por
/// palabra que acompaña a la voz.
///
/// Está pensado para dos públicos a la vez: quien no ve la pantalla escucha el
/// texto, y quien no oye lee la transcripción resaltada en la franja inferior.
class AccessibilityReadingState {
  final ValueNotifier<String?> currentText = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isHighlighting = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentWordIndex = ValueNotifier<int>(0);

  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;
  Timer? _fallbackTimer;

  Future<void> initialize() async {
    if (_ttsInitialized || kIsWeb) return;

    try {
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      _flutterTts.setProgressHandler((text, start, end, word) {
        _syncHighlightWithSpokenWord(start);
      });
      _flutterTts.setCompletionHandler(clearHighlight);
      _flutterTts.setCancelHandler(clearHighlight);
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
    currentWordIndex.value = 0;
    isHighlighting.value = true;

    if (context.mounted) {
      announceForAccessibility(context, content);
    }

    if (kIsWeb) {
      web_speech.speakWithBrowserVoice(content);
      _startFallbackHighlight(content);
      return;
    }

    try {
      await initialize();
      await _flutterTts.speak(content);
    } catch (e, st) {
      debugPrint('Error al reproducir TTS: $e');
      debugPrint(st.toString());
      _startFallbackHighlight(content);
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
    currentWordIndex.value = 0;
  }

  /// Traduce el offset de caracteres que reporta el motor de voz al índice de
  /// palabra que debe resaltarse en la transcripción.
  void _syncHighlightWithSpokenWord(int startOffset) {
    final content = currentText.value;
    if (content == null || content.isEmpty) return;

    final safeOffset = startOffset.clamp(0, content.length);
    final wordsBefore = content
        .substring(0, safeOffset)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;

    currentWordIndex.value = wordsBefore;
  }

  /// Resaltado aproximado para plataformas sin callbacks de progreso (web).
  ///
  /// Avanza al ritmo estimado de lectura en voz alta en español y se detiene
  /// solo cuando termina el texto, no con un tiempo fijo.
  void _startFallbackHighlight(String content) {
    final words = _splitWords(content);
    if (words.isEmpty) return;

    var index = 0;
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
      if (!isHighlighting.value || index >= words.length) {
        timer.cancel();
        clearHighlight();
        return;
      }
      currentWordIndex.value = index;
      index++;
    });
  }

  static List<String> _splitWords(String content) =>
      content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  void dispose() {
    _fallbackTimer?.cancel();
    currentText.dispose();
    isHighlighting.dispose();
    currentWordIndex.dispose();
  }
}

/// Envuelve una pantalla y muestra, mientras se lee en voz alta, una franja
/// inferior con la transcripción y la palabra actual resaltada.
class ReadableScreenHighlight extends StatelessWidget {
  const ReadableScreenHighlight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: accessibilityReadingState.isHighlighting,
      builder: (context, isActive, _) {
        final text = accessibilityReadingState.currentText.value;
        if (!isActive || text == null || text.trim().isEmpty) {
          return child;
        }

        final words = AccessibilityReadingState._splitWords(text);

        return Column(
          children: [
            Expanded(child: child),
            ValueListenableBuilder<int>(
              valueListenable: accessibilityReadingState.currentWordIndex,
              builder: (context, index, _) {
                return Semantics(
                  liveRegion: true,
                  label: 'Transcripción de la lectura en voz alta',
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      border: Border(
                        top: BorderSide(
                          color: Colors.orange.shade800,
                          width: 2,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          children: List.generate(words.length, (i) {
                            final isCurrent = i == index;
                            return TextSpan(
                              text: '${words[i]} ',
                              style: TextStyle(
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                backgroundColor: isCurrent
                                    ? Colors.yellow.shade600
                                    : null,
                                decoration: isCurrent
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
