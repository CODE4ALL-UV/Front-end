import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';

final accessibilityReadingState = AccessibilityReadingState();

class ScreenContentExtractor {
  static String extractFromContext(BuildContext context) {
    final buffer = StringBuffer();
    final seen = <Element>{};

    void visit(Element element) {
      if (!seen.add(element)) return;

      final widget = element.widget;

      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        if (text.trim().isNotEmpty) {
          if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
            buffer.write(' ');
          }
          buffer.write(text.trim());
        }
      } else if (widget is TextField) {
        final decoration = widget.decoration;
        final labelText = decoration?.labelText?.trim();
        if (labelText != null && labelText.isNotEmpty) {
          if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
            buffer.write(' ');
          }
          buffer.write(labelText);
        }
        final hintText = decoration?.hintText?.trim();
        if (hintText != null && hintText.isNotEmpty) {
          if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
            buffer.write(' ');
          }
          buffer.write(hintText);
        }
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
    if (text.isNotEmpty) {
      return text.length > 260 ? text.substring(0, 260) : text;
    }

    final fallback = context.widget.toString();
    return fallback.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

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
}

@JS('window.speechSynthesis')
external SpeechSynthesis? get speechSynthesis;

class AccessibilityReadingState {
  final ValueNotifier<String?> currentText = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isHighlighting = ValueNotifier<bool>(false);
  final ValueNotifier<int> currentWordIndex = ValueNotifier<int>(0);
  final FlutterTts _flutterTts = FlutterTts();
  bool _ttsInitialized = false;

  Future<void> initialize() async {
    if (_ttsInitialized || kIsWeb) return;

    try {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.95);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      _ttsInitialized = true;
    } catch (e, st) {
      debugPrint('Error inicializando TTS: $e');
      debugPrint(st.toString());
    }
  }

  void _speakWithBrowserVoice(String text) {
    try {
      final speech = speechSynthesis;
      if (speech == null) return;

      final utterance = SpeechSynthesisUtterance(text);
      utterance.lang = 'es-ES';
      utterance.rate = 0.95;
      utterance.pitch = 1.0;

      speech.cancel();
      speech.speak(utterance);
    } catch (e, st) {
      debugPrint('Error usando SpeechSynthesis: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> read(String text, BuildContext context) async {
    final content = text.trim();
    if (content.isEmpty) return;

    currentText.value = content;
    currentWordIndex.value = 0;
    isHighlighting.value = true;

    if (kIsWeb) {
      _speakWithBrowserVoice(content);
    } else {
      try {
        await initialize();
        await _flutterTts.stop();
        await _flutterTts.speak(content);
      } catch (e, st) {
        debugPrint('Error al reproducir TTS: $e');
        debugPrint(st.toString());
      }
    }

    if (context.mounted) {
      SemanticsBinding.instance.ensureSemantics();
      // ignore: deprecated_member_use
      SemanticsService.announce(content, Directionality.of(context));
    }

    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return;

    var index = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 800), (tick) {
      if (!isHighlighting.value) {
        tick.cancel();
        return;
      }

      if (index < words.length) {
        currentWordIndex.value = index;
        index++;
      } else {
        tick.cancel();
        isHighlighting.value = false;
        currentWordIndex.value = 0;
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      timer.cancel();
      if (isHighlighting.value) {
        isHighlighting.value = false;
        currentWordIndex.value = 0;
      }
    });
  }

  void clearHighlight() {
    isHighlighting.value = false;
  }
}

class ReadableScreenHighlight extends StatelessWidget {
  const ReadableScreenHighlight({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: accessibilityReadingState.currentText,
      builder: (_, currentText, _) {
        final isActive =
            accessibilityReadingState.isHighlighting.value &&
            (currentText?.trim().isNotEmpty ?? false);

        if (!isActive) {
          return child;
        }

        final words = currentText!
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();
        final index = accessibilityReadingState.currentWordIndex.value;

        return Column(
          children: [
            Expanded(child: child),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border(
                  top: BorderSide(color: Colors.orange.shade700, width: 1.2),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  children: List.generate(words.length, (i) {
                    final word = words[i];
                    final isCurrent = i == index;
                    return TextSpan(
                      text: '$word ',
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        backgroundColor: isCurrent
                            ? Colors.yellow.shade400
                            : null,
                        decoration: isCurrent ? TextDecoration.underline : null,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
