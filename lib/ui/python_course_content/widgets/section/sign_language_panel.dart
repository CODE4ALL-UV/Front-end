import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/hand_sign_painter_widget.dart';
import 'sign_asset_index.dart';

/// Configuración de una letra del alfabeto manual.
///
/// Cada dedo se describe con un grado de extensión (0 cerrado, 1 a medias,
/// 2 estirado). Con eso basta para que las letras se distingan claramente a
/// simple vista.

/// Quita tildes y pasa a mayúscula, que es como se deletrea.
String _normalize(String input) {
  const from = 'áàäâéèëêíìïîóòöôúùüûÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛ';
  const to = 'aaaaeeeeiiiioooouuuuAAAAEEEEIIIIOOOOUUUU';

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString().toUpperCase();
}

/// Panel que deletrea en alfabeto manual el texto del cuadro de subtítulos.
///
/// **Qué es y qué no es.** Esto es *dactilología*: deletrea letra por letra lo
/// que dice el subtítulo, con una mano esquemática dibujada en código. No es
/// una interpretación en Lengua de Señas Colombiana, que tiene su propia
/// gramática y no se construye deletreando.
///
/// Se incluye porque acompaña la lectura del subtítulo y ayuda con los
/// términos técnicos —que en LSC se deletrean de verdad—, pero **no sustituye
/// a un intérprete**.
///
/// **Cómo poner manos reales.** Deja una foto por letra en
/// `assets/sign_language/letras/` y un clip por palabra en
/// `assets/sign_language/palabras/`. El panel las detecta solo, a través de
/// [SignAssetIndex], y deja de dibujar. No hay ningún interruptor que activar
/// ni ninguna otra pantalla que tocar. Las instrucciones de nombrado están en
/// el README de cada carpeta.
class SignLanguagePanel extends StatefulWidget {
  const SignLanguagePanel({
    super.key,
    required this.text,
    this.isPlaying = true,
  });

  /// Texto que se está mostrando en el cuadro de subtítulos.
  final String text;

  /// Si está en falso, la animación se detiene en la letra actual.
  final bool isPlaying;

  @override
  State<SignLanguagePanel> createState() => _SignLanguagePanelState();
}

class _SignLanguagePanelState extends State<SignLanguagePanel> {
  /// Ritmo de deletreo. Algo más lento que el habla para poder seguirlo.
  static const Duration _letterDuration = Duration(milliseconds: 620);

  Timer? _timer;
  List<String> _letters = const [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadText(widget.text);

    // Si hay manos reales empaquetadas, se usan en cuanto se sepa cuáles.
    SignAssetIndex.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant SignLanguagePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _loadText(widget.text);
      return;
    }
    if (oldWidget.isPlaying != widget.isPlaying) {
      widget.isPlaying ? _start() : _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadText(String text) {
    _timer?.cancel();
    _letters = _normalize(text).split('');
    _index = 0;
    if (widget.isPlaying && _letters.isNotEmpty) _start();
    if (mounted) setState(() {});
  }

  void _start() {
    _timer?.cancel();
    if (_letters.isEmpty) return;

    _timer = Timer.periodic(_letterDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Al terminar la frase se queda quieto: el siguiente subtítulo la
      // reemplazará y volverá a empezar.
      if (_index >= _letters.length - 1) {
        timer.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  String get _currentLetter =>
      _letters.isEmpty ? '' : _letters[_index.clamp(0, _letters.length - 1)];

  /// Palabra a la que pertenece la letra actual, para dar contexto.
  String get _currentWord {
    if (_letters.isEmpty) return '';
    var start = _index;
    while (start > 0 && _letters[start - 1].trim().isNotEmpty) {
      start--;
    }
    var end = _index;
    while (end < _letters.length - 1 && _letters[end + 1].trim().isNotEmpty) {
      end++;
    }
    return _letters.sublist(start, end + 1).join().trim();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final letter = _currentLetter;
    final word = _currentWord;
    final shape = signAlphabet[letter];

    final index = SignAssetIndex.instance;
    final letterAsset = index.letterAsset(letter);
    final wordAsset = word.isEmpty ? null : index.wordAsset(word);

    return Semantics(
      // El contenido ya está disponible como texto en el cuadro de
      // subtítulos: repetirlo aquí solo duplicaría la lectura por voz.
      label: 'Panel de señas, acompaña al subtítulo',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appColorScheme.surface,
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
            border: Border.all(color: appSemanticColors.infoBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sign_language,
                    size: 17,
                    color: appSemanticColors.infoBorder,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Señas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: appSemanticColors.infoBackground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Mitad y mitad: a la izquierda el deletreo letra a letra, a la
              // derecha la seña de la palabra completa.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _HalfTile(
                      label: 'Dactilología',
                      caption: letter.trim().isEmpty ? '␣' : letter,
                      captionIsLarge: true,
                      footnote: (shape?.hasMotion ?? false)
                          ? 'lleva movimiento'
                          : null,
                      child: _letters.isEmpty
                          ? _HandDrawing(shape: null, idle: true)
                          : (letterAsset != null
                                ? _AssetHand(
                                    assetPath: letterAsset,
                                    letter: letter,
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: KeyedSubtree(
                                      key: ValueKey<String>('$letter$_index'),
                                      child: _HandDrawing(shape: shape),
                                    ),
                                  )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HalfTile(
                      label: 'Lengua de señas',
                      caption: word.isEmpty ? '—' : word,
                      child: _SignDisplay(word: word, assetPath: wordAsset),
                    ),
                  ),
                ],
              ),
              if (_letters.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _letters.length,
                    minHeight: 4,
                    backgroundColor: appSemanticColors.infoBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      appSemanticColors.infoBackground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Una de las dos mitades del panel: título, recuadro visual y pie.
class _HalfTile extends StatelessWidget {
  const _HalfTile({
    required this.label,
    required this.caption,
    required this.child,
    this.captionIsLarge = false,
    this.footnote,
  });

  /// Alto del recuadro visual.
  ///
  /// Fijo y modesto: el panel acompaña al subtítulo, no debe competir con el
  /// video ni empujar el resto de la lección fuera de la pantalla.
  static const double visualHeight = 92;

  final String label;
  final String caption;
  final Widget child;
  final bool captionIsLarge;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: appSemanticColors.infoText,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(height: visualHeight, child: child),
        const SizedBox(height: 6),
        Text(
          caption,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: captionIsLarge ? 22 : 12.5,
            height: 1.1,
            fontWeight: captionIsLarge ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: captionIsLarge ? 0 : 0.8,
            color: appSemanticColors.infoText,
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 2),
          Text(
            footnote!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              color: appSemanticColors.infoText,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dibuja la mano de una letra ocupando todo el hueco que le den.
class _HandDrawing extends StatelessWidget {
  const _HandDrawing({required this.shape, this.idle = false});

  final HandShape? shape;

  /// Mano en reposo, cuando todavía no hay subtítulo.
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    // SizedBox.expand es imprescindible: un CustomPaint sin hijo se queda en
    // tamaño cero cuando recibe restricciones sueltas, que es justo lo que le
    // da el Stack interno de AnimatedSwitcher. Sin esto la mano no se ve.
    return SizedBox.expand(
      child: CustomPaint(
        painter: HandPainter(
          shape: idle
              ? const HandShape(
                  thumb: 1,
                  index: 1,
                  middle: 1,
                  ring: 1,
                  pinky: 1,
                )
              : shape,
          tones: idle ? SkinTones.idle : (SkinTones.warm),
          background: idle
              ? appColorScheme.surface
              : appSemanticColors.infoBackground,
        ),
      ),
    );
  }
}

/// Mitad derecha: la seña de la palabra completa.
///
/// Cuando hay material grabado por un intérprete para esa palabra se muestra
/// aquí. Mientras no lo haya, se dice con todas las letras que esa palabra se
/// está deletreando, en lugar de fingir una seña que no existe.
class _SignDisplay extends StatelessWidget {
  const _SignDisplay({required this.word, required this.assetPath});

  final String word;

  /// Clip o imagen de la seña de esta palabra, si existe.
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final container = BoxDecoration(
      color: appColorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: appSemanticColors.infoBorder),
    );

    final path = assetPath;
    if (path != null) {
      return Container(
        decoration: container,
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => _fallback(context),
        ),
      );
    }

    return Container(decoration: container, child: _fallback(context));
  }

  Widget _fallback(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          word.isEmpty ? Icons.hourglass_empty : Icons.spellcheck,
          size: 26,
          color: appSemanticColors.infoText,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            word.isEmpty ? 'esperando' : 'se deletrea',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: appSemanticColors.infoText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Foto real de una letra, cuando está empaquetada en la app.
class _AssetHand extends StatelessWidget {
  const _AssetHand({required this.assetPath, required this.letter});

  final String assetPath;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      // Si la imagen falla al cargarse, se dibuja la mano en lugar de dejar
      // un hueco.
      errorBuilder: (context, error, stack) =>
          _HandDrawing(shape: signAlphabet[letter]),
    );
  }
}
