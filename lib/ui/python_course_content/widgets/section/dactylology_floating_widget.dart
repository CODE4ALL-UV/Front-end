import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/hand_sign_painter_widget.dart';
import 'sign_asset_index.dart';
import 'sign_language_panel.dart';

/// Lector de dactilología plegable que flota sobre el contenido.
///
/// Desplegado es el mismo lector del manual web (`web/manual.html`, el
/// `.dock`): la mano grande con la letra al lado, la palabra entera en manos
/// pequeñas, el avance por palabras y los botones para pausar, repetir,
/// saltar de palabra y cambiar la velocidad. Quien aprendió a usarlo en el
/// manual se lo encuentra igual dentro de la app.
///
/// Como el panel de señas, es dactilología: deletrea letra por letra con una
/// mano esquemática, no interpreta en Lengua de Señas Colombiana.
class DactylologyFloatingWidget extends StatefulWidget {
  const DactylologyFloatingWidget({
    super.key,
    required this.text,
    this.showWordSigns = false,
  });

  final String text;

  /// En «Avanzado», si hay una seña grabada para la palabra, se muestra.
  final bool showWordSigns;

  @override
  State<DactylologyFloatingWidget> createState() =>
      _DactylologyFloatingWidgetState();
}

class _DactylologyFloatingWidgetState extends State<DactylologyFloatingWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final colors = context.colorScheme;

    return Material(
      color: Colors.transparent,
      child: _expanded
          ? Container(
              width: math.min(384.0, screen.width - 32),
              // Con la pantalla baja el lector se desplaza por dentro en vez
              // de salirse por arriba.
              constraints: BoxConstraints(maxHeight: screen.height * 0.7),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D000000),
                    blurRadius: 36,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: _DactylologyReader(
                  text: widget.text,
                  showWordSigns: widget.showWordSigns,
                  onClose: () => setState(() => _expanded = false),
                ),
              ),
            )
          : Semantics(
              button: true,
              label: 'Mostrar lector de dactilología',
              child: FloatingActionButton.small(
                heroTag: 'dactylology-reader',
                tooltip: 'Mostrar lector de dactilología',
                onPressed: () => setState(() => _expanded = true),
                child: const Icon(Icons.sign_language),
              ),
            ),
    );
  }
}

/// Signos que se quitan del principio y del final de cada palabra antes de
/// deletrearla. Son los mismos que quita el manual.
final RegExp _edgeMark = RegExp(r'''[.,;:!?¡¿«»"“”'‘’()\[\]{}…—–·•*-]''');

/// Las palabras del texto, cada una partida en las letras que se deletrean.
List<List<String>> _spellWords(String text) {
  final words = <List<String>>[];
  for (final raw in text.trim().split(RegExp(r'\s+'))) {
    var start = 0;
    var end = raw.length;
    while (start < end && _edgeMark.hasMatch(raw[start])) {
      start++;
    }
    while (end > start && _edgeMark.hasMatch(raw[end - 1])) {
      end--;
    }
    if (end == start) continue;
    words.add(
      normalizeForSpelling(
        raw.substring(start, end),
      ).runes.map(String.fromCharCode).toList(),
    );
  }
  return words;
}

/// El texto que se deletrea, en una línea y recortado, para la cabecera.
String _preview(String text) {
  final flat = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (flat.isEmpty) return '';
  return '«${flat.length > 48 ? '${flat.substring(0, 47)}…' : flat}»';
}

/// El lector desplegado: cabecera, mano, palabra, avance y controles.
class _DactylologyReader extends StatefulWidget {
  const _DactylologyReader({
    required this.text,
    required this.showWordSigns,
    required this.onClose,
  });

  final String text;
  final bool showWordSigns;
  final VoidCallback onClose;

  @override
  State<_DactylologyReader> createState() => _DactylologyReaderState();
}

class _DactylologyReaderState extends State<_DactylologyReader> {
  /// Ritmos de deletreo, los del manual. «Normal» es el del panel de señas.
  static const List<(String, int)> _speeds = [
    ('Lenta', 950),
    ('Normal', 620),
    ('Rápida', 400),
  ];

  /// La velocidad y el tamaño elegidos se mantienen al cambiar de pantalla,
  /// como el manual los recuerda al volver.
  static int _speed = 1;
  static bool _minimized = false;

  /// Ancho de cada mano pequeña de la tira, con su borde, y el hueco entre
  /// ellas. Hacen falta para llevar la letra actual a la vista.
  static const double _stripItemWidth = 50;
  static const double _stripItemGap = 4;

  final ScrollController _strip = ScrollController();
  Timer? _timer;

  List<List<String>> _words = const [];
  int _word = 0;
  int _letter = 0;

  /// La pausa entre una palabra y la siguiente.
  bool _gap = false;
  bool _playing = false;

  /// Llegó al final del texto: el botón principal vuelve a empezar.
  bool _ended = false;

  /// Cambia con cada texto nuevo, para que la mano entre aunque la letra
  /// sea la misma.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();

    // Si hay manos reales empaquetadas, se usan en cuanto se sepa cuáles.
    SignAssetIndex.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _DactylologyReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _strip.dispose();
    super.dispose();
  }

  void _load() {
    _timer?.cancel();
    _words = _spellWords(widget.text);
    _word = 0;
    _letter = 0;
    _gap = false;
    _ended = false;
    _generation++;
    _playing = _words.isNotEmpty;
    if (_playing) _schedule();
    _keepLetterInView();
  }

  void _schedule() {
    _timer?.cancel();
    final ms = _speeds[_speed].$2;
    _timer = Timer(
      Duration(milliseconds: _gap ? (ms * 0.6).round() : ms),
      _tick,
    );
  }

  void _tick() {
    if (!mounted || _words.isEmpty) return;
    final word = _words[_word];
    setState(() {
      if (_gap) {
        _gap = false;
        _word++;
        _letter = 0;
      } else if (_letter < word.length - 1) {
        _letter++;
      } else if (_word < _words.length - 1) {
        _gap = true;
      } else {
        // Al terminar el texto se queda quieto en la última letra.
        _playing = false;
        _ended = true;
      }
    });
    if (_playing) _schedule();
    _keepLetterInView();
  }

  void _setPlaying(bool on) {
    _timer?.cancel();
    setState(() {
      _playing = on && _words.isNotEmpty;
      if (_playing) _ended = false;
    });
    if (_playing) _schedule();
  }

  void _jump(int word) {
    if (_words.isEmpty) return;
    setState(() {
      _word = word.clamp(0, _words.length - 1);
      _letter = 0;
      _gap = false;
      _ended = false;
    });
    if (_playing) _schedule();
    _keepLetterInView();
  }

  void _togglePlay() {
    if (!_ended) {
      _setPlaying(!_playing);
      return;
    }
    _jump(0);
    _setPlaying(true);
  }

  void _nextSpeed() {
    setState(() => _speed = (_speed + 1) % _speeds.length);
    if (_playing) _schedule();
  }

  /// Lleva la letra que se está haciendo al centro de la tira si se salió.
  void _keepLetterInView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_strip.hasClients) return;
      final position = _strip.position;
      final left = _letter * (_stripItemWidth + _stripItemGap);
      final right = left + _stripItemWidth;
      if (left >= position.pixels &&
          right <= position.pixels + position.viewportDimension) {
        return;
      }
      _strip.jumpTo(
        (left - (position.viewportDimension - _stripItemWidth) / 2).clamp(
          0.0,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final muted = colors.onSurfaceVariant;
    final accent = AppContrast.readableOn(
      colors.secondary,
      colors.surface,
      AppContrast.ui,
    );
    final track = Color.alphaBlend(
      colors.onSurface.withValues(alpha: 0.07),
      colors.surface,
    );
    final instant = MediaQuery.of(context).disableAnimations;

    final word = _words.isEmpty ? null : _words[_word];
    final letter = word == null || _gap ? '' : word[_letter];
    final gap = SizedBox(height: _minimized ? 6 : 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(colors, muted, accent),
        gap,
        // La mano y la tira se ocultan al lector de pantalla: ese texto ya
        // está en la pantalla.
        ExcludeSemantics(child: _current(word, letter, colors, muted, instant)),
        if (!_minimized) ...[
          if (word != null) ...[
            gap,
            ExcludeSemantics(child: _wordStrip(word, colors, track)),
          ],
          if (widget.showWordSigns && word != null) _wordSign(word, muted),
          gap,
          _progress(muted, accent, track, instant),
          gap,
          _controls(),
          gap,
          Text(
            'Deletrea el texto de esta pantalla con el alfabeto manual. Es '
            'dactilología, no Lengua de Señas Colombiana.',
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ],
      ],
    );
  }

  Widget _header(ColorScheme colors, Color muted, Color accent) {
    final source = _preview(widget.text);
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: muted,
      minimumSize: const Size(44, 44),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sign_language, size: 20, color: accent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Dactilología',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              if (source.isNotEmpty)
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: muted),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: _minimized ? 'Agrandar el lector' : 'Encoger el lector',
          onPressed: () => setState(() => _minimized = !_minimized),
          iconSize: 20,
          style: buttonStyle,
          icon: Icon(
            _minimized ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
        ),
        IconButton(
          tooltip: 'Ocultar lector de señas',
          onPressed: widget.onClose,
          iconSize: 20,
          style: buttonStyle,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  /// La mano grande y, al lado, la letra con su nota.
  Widget _current(
    List<String>? word,
    String letter,
    ColorScheme colors,
    Color muted,
    bool instant,
  ) {
    final handSize = _minimized
        ? 64.0
        : math.min(136.0, MediaQuery.sizeOf(context).width * 0.3);
    final shape = signAlphabet[letter];
    final note = word == null
        ? 'No hay texto que deletrear.'
        : _gap
        ? 'Espacio entre palabras'
        : shape != null
        ? (shape.hasMotion ? 'Lleva movimiento' : '')
        : RegExp(r'\d').hasMatch(letter)
        ? 'Número: se muestra tal cual'
        : 'Signo: se muestra tal cual';

    return Row(
      children: [
        // Cada letra nueva entra con un pequeño salto, como en el manual.
        TweenAnimationBuilder<double>(
          key: ValueKey<String>('$_generation-$_word-$_letter-$_gap'),
          tween: Tween(begin: 0, end: 1),
          duration: instant ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: 0.35 + 0.65 * t,
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
          child: _SignImage(char: letter, size: handSize),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word == null
                    ? '—'
                    : _gap
                    ? '␣'
                    : letter,
                key: const ValueKey('dactylology-letter'),
                style: TextStyle(
                  fontSize: _minimized ? 36 : 56,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(note, style: TextStyle(fontSize: 14, color: muted)),
            ],
          ),
        ),
      ],
    );
  }

  /// La palabra entera en manos pequeñas, para leerla de un vistazo.
  Widget _wordStrip(List<String> word, ColorScheme colors, Color track) {
    return SingleChildScrollView(
      controller: _strip,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
      child: Row(
        children: [
          for (var i = 0; i < word.length; i++)
            Padding(
              padding: EdgeInsets.only(
                right: i == word.length - 1 ? 0 : _stripItemGap,
              ),
              child: Opacity(
                opacity: _gap || i < _letter ? 0.5 : 1,
                child: Container(
                  width: _stripItemWidth,
                  padding: const EdgeInsets.fromLTRB(3, 4, 3, 3),
                  decoration: BoxDecoration(
                    color: !_gap && i == _letter ? track : null,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 2,
                      color: !_gap && i == _letter
                          ? colors.tertiary
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SignImage(char: word[i], size: 40),
                      const SizedBox(height: 2),
                      Text(
                        word[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// En «Avanzado», la seña de la palabra completa cuando hay una grabada.
  ///
  /// Si no la hay no se muestra nada: la tira ya deja claro que la palabra
  /// se deletrea, y no se finge una seña que no existe.
  Widget _wordSign(List<String> word, Color muted) {
    final asset = SignAssetIndex.instance.wordAsset(word.join());
    if (asset == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 92,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seña de la palabra «${word.join()}»',
              style: TextStyle(fontSize: 13, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(Color muted, Color accent, Color track, bool instant) {
    final total = _words.length;
    final value = total == 0
        ? 0.0
        : (_word + (_gap ? 1 : (_letter + 1) / _words[_word].length)) / total;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              height: 5,
              color: track,
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: instant
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                alignment: Alignment.centerLeft,
                widthFactor: value,
                heightFactor: 1,
                child: ColoredBox(color: accent),
              ),
            ),
          ),
        ),
        if (total > 0) ...[
          const SizedBox(width: 10),
          Text(
            'Palabra ${_word + 1} de $total',
            style: TextStyle(
              fontSize: 12,
              color: muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  Widget _controls() {
    final playLabel = _ended
        ? 'Deletrear otra vez desde el principio'
        : _playing
        ? 'Pausar'
        : 'Seguir deletreando';

    return Row(
      children: [
        _ReaderButton(
          icon: Icons.skip_previous,
          tooltip: 'Palabra anterior',
          onPressed: () => _jump(_word - 1),
        ),
        const SizedBox(width: 6),
        _ReaderButton(
          icon: Icons.refresh,
          tooltip: 'Repetir la palabra',
          onPressed: () => _jump(_word),
        ),
        const SizedBox(width: 6),
        _ReaderButton(
          icon: _ended
              ? Icons.replay
              : _playing
              ? Icons.pause
              : Icons.play_arrow,
          tooltip: playLabel,
          primary: true,
          onPressed: _togglePlay,
        ),
        const SizedBox(width: 6),
        _ReaderButton(
          icon: Icons.skip_next,
          tooltip: 'Palabra siguiente',
          onPressed: () => _jump(_word + 1),
        ),
        const SizedBox(width: 6),
        // La velocidad va sola a la derecha; en un teléfono estrecho se
        // encoge antes que empujar a los demás botones.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _ReaderButton(
                icon: Icons.speed,
                label: _speeds[_speed].$1,
                tooltip: 'Cambiar la velocidad',
                onPressed: _nextSpeed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón del lector: cuadrado con borde, como los del manual; el principal
/// lleva el color de los botones principales de la app.
class _ReaderButton extends StatelessWidget {
  const _ReaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final String? label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final background = primary
        ? colors.primary
        : Theme.of(context).scaffoldBackgroundColor;
    final foreground = primary ? colors.onPrimary : colors.onSurface;

    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(
            color: primary ? colors.primary : colors.outlineVariant,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              // El estilo va en el texto y no en el botón: así se suma al del
              // tema y conserva su fuente.
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La seña de un carácter, del tamaño que se pida.
///
/// Usa la foto real si está empaquetada y, si no, la mano dibujada. Números y
/// signos no tienen mano en el alfabeto manual: se muestran tal cual. Sin
/// carácter, la mano en reposo.
class _SignImage extends StatelessWidget {
  const _SignImage({required this.char, required this.size});

  final String char;
  final double size;

  @override
  Widget build(BuildContext context) {
    final background = context.messageColors.infoBackground;

    if (char.isEmpty) {
      return _paint(
        const HandShape(thumb: 1, index: 1, middle: 1, ring: 1, pinky: 1),
        SkinTones.idle,
        background,
      );
    }

    final shape = signAlphabet[char];
    final drawn = shape != null
        ? _paint(shape, SkinTones.warm, background)
        : _glyph(context, background);

    final asset = SignAssetIndex.instance.letterAsset(char);
    if (asset == null) return drawn;
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        // Si la foto falla al cargarse, se dibuja la mano en su lugar.
        errorBuilder: (context, error, stack) => drawn,
      ),
    );
  }

  Widget _paint(HandShape shape, SkinTones tones, Color background) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: HandPainter(
          shape: shape,
          tones: tones,
          background: background,
        ),
      ),
    );
  }

  Widget _glyph(BuildContext context, Color background) {
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Container(
          width: size * 0.94,
          height: size * 0.94,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Text(
            char,
            style: TextStyle(
              fontSize: size * 0.46,
              height: 1,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
