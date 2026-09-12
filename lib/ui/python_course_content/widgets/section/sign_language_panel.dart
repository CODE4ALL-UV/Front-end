import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';

import 'section_theme.dart';
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
    final palette = SectionPalette.of(context);
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
            color: palette.surface,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.sign_language, size: 17, color: palette.accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Señas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: palette.accent,
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
                      palette: palette,
                      caption: letter.trim().isEmpty ? '␣' : letter,
                      captionIsLarge: true,
                      footnote: (shape?.hasMotion ?? false)
                          ? 'lleva movimiento'
                          : null,
                      child: _letters.isEmpty
                          ? _HandDrawing(
                              shape: null,
                              palette: palette,
                              idle: true,
                            )
                          : (letterAsset != null
                                ? _AssetHand(
                                    assetPath: letterAsset,
                                    letter: letter,
                                    palette: palette,
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: KeyedSubtree(
                                      key: ValueKey<String>('$letter$_index'),
                                      child: _HandDrawing(
                                        shape: shape,
                                        palette: palette,
                                      ),
                                    ),
                                  )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _HalfTile(
                      label: 'Lengua de señas',
                      palette: palette,
                      caption: word.isEmpty ? '—' : word,
                      child: _SignDisplay(
                        word: word,
                        palette: palette,
                        assetPath: wordAsset,
                      ),
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
                    backgroundColor: palette.border,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
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
    required this.palette,
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
  final SectionPalette palette;
  final String caption;
  final Widget child;
  final bool captionIsLarge;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
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
            color: palette.textSecondary,
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
            color: palette.textPrimary,
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
              color: palette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dibuja la mano de una letra ocupando todo el hueco que le den.
class _HandDrawing extends StatelessWidget {
  const _HandDrawing({
    required this.shape,
    required this.palette,
    this.idle = false,
  });

  final HandShape? shape;
  final SectionPalette palette;

  /// Mano en reposo, cuando todavía no hay subtítulo.
  final bool idle;

  @override
  Widget build(BuildContext context) {
    // SizedBox.expand es imprescindible: un CustomPaint sin hijo se queda en
    // tamaño cero cuando recibe restricciones sueltas, que es justo lo que le
    // da el Stack interno de AnimatedSwitcher. Sin esto la mano no se ve.
    return SizedBox.expand(
      child: CustomPaint(
        painter: _HandPainter(
          shape: idle
              ? const HandShape(
                  thumb: 1,
                  index: 1,
                  middle: 1,
                  ring: 1,
                  pinky: 1,
                )
              : shape,
          tones: idle
              ? _SkinTones.idle
              : (palette.isDark ? _SkinTones.warmDark : _SkinTones.warm),
          background: idle ? palette.surfaceAlt : palette.accentSoft,
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
  const _SignDisplay({
    required this.word,
    required this.palette,
    required this.assetPath,
  });

  final String word;
  final SectionPalette palette;

  /// Clip o imagen de la seña de esta palabra, si existe.
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final container = BoxDecoration(
      color: palette.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: palette.border),
    );

    final path = assetPath;
    if (path != null) {
      return Container(
        decoration: container,
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => _fallback(),
        ),
      );
    }

    return Container(decoration: container, child: _fallback());
  }

  Widget _fallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          word.isEmpty ? Icons.hourglass_empty : Icons.spellcheck,
          size: 26,
          color: palette.textSecondary,
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
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Foto real de una letra, cuando está empaquetada en la app.
class _AssetHand extends StatelessWidget {
  const _AssetHand({
    required this.assetPath,
    required this.letter,
    required this.palette,
  });

  final String assetPath;
  final String letter;
  final SectionPalette palette;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      // Si la imagen falla al cargarse, se dibuja la mano en lugar de dejar
      // un hueco.
      errorBuilder: (context, error, stack) =>
          _HandDrawing(shape: signAlphabet[letter], palette: palette),
    );
  }
}

/// Tonos con los que se pinta la mano.
@immutable
class _SkinTones {
  const _SkinTones({
    required this.base,
    required this.shade,
    required this.light,
    required this.line,
    required this.nail,
  });

  final Color base;
  final Color shade;
  final Color light;
  final Color line;
  final Color nail;

  /// Tono cálido para el tema claro.
  static const warm = _SkinTones(
    base: Color(0xFFF0C3A0),
    shade: Color(0xFFD69C76),
    light: Color(0xFFFCE4D0),
    line: Color(0xFF8A5A3C),
    nail: Color(0xFFF9E2D2),
  );

  /// Algo más profundo en oscuro, para no deslumbrar.
  static const warmDark = _SkinTones(
    base: Color(0xFFD9A57F),
    shade: Color(0xFFB27E5B),
    light: Color(0xFFEFCAAC),
    line: Color(0xFF5E3A26),
    nail: Color(0xFFE8C8B1),
  );

  /// Mano en reposo, en gris, cuando todavía no hay subtítulo.
  static const idle = _SkinTones(
    base: Color(0xFFCFD8E3),
    shade: Color(0xFFAAB6C4),
    light: Color(0xFFE8EDF3),
    line: Color(0xFF7B8896),
    nail: Color(0xFFE4EAF1),
  );
}

/// Dibuja la mano de una letra del alfabeto manual.
///
/// Es una ilustración original hecha con `Path`: palma con la base del pulgar,
/// dedos cónicos con punta redondeada y uña, muñeca, sombreado y pliegues de
/// nudillos. La forma de cada letra sale de [HandShape].
class _HandPainter extends CustomPainter {
  _HandPainter({
    required this.shape,
    required this.tones,
    required this.background,
  });

  final HandShape? shape;
  final _SkinTones tones;
  final Color background;

  /// Largo de cada dedo respecto a la palma: índice, corazón, anular, meñique.
  static const List<double> _lengthFactor = [1.02, 1.12, 1.0, 0.80];

  /// Apertura natural de cada dedo, en radianes.
  static const List<double> _baseAngle = [-0.11, -0.035, 0.045, 0.125];

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, side * 0.47, Paint()..color = background);

    final current = shape;
    if (current == null) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (current.pointsDown) canvas.rotate(math.pi);

    final palmW = side * 0.40;
    final palmH = side * 0.33;
    final knuckleY = -side * 0.04;
    final wristY = knuckleY + palmH;

    final fill = Paint()..color = tones.base;
    final shade = Paint()..color = tones.shade;
    final stroke = Paint()
      ..color = tones.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.009
      ..strokeJoin = StrokeJoin.round;

    // --- muñeca -----------------------------------------------------------
    final wrist = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -palmW * 0.30,
        wristY - palmH * 0.10,
        palmW * 0.60,
        side * 0.13,
      ),
      Radius.circular(side * 0.05),
    );
    canvas.drawRRect(wrist, shade);
    canvas.drawRRect(wrist, stroke);

    // --- dedos (detrás de la palma, para esconder su nacimiento) ----------
    final fingerW = palmW * 0.185;
    final extensions = current.fingers;

    for (var i = 0; i < extensions.length; i++) {
      final extension = extensions[i];
      final spread = current.spread;
      final angle = _baseAngle[i] * (1 + spread * 2.2);

      var baseX = -palmW / 2 + palmW * (i + 0.5) / 4;
      if (current.crossed && i < 2) {
        baseX += i == 0 ? fingerW * 0.55 : -fingerW * 0.55;
      }
      final base = Offset(baseX, knuckleY + palmH * 0.06);

      if (extension == 0) {
        // Dedo recogido: se ve el nudillo asomando sobre la palma.
        final bump = Rect.fromCenter(
          center: Offset(baseX, knuckleY + fingerW * 0.10),
          width: fingerW * 1.12,
          height: fingerW * 1.05,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bump, Radius.circular(fingerW * 0.5)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bump, Radius.circular(fingerW * 0.5)),
          stroke,
        );
        continue;
      }

      final full = palmH * _lengthFactor[i] * 1.06;
      final length = extension == 2 ? full : full * 0.50;
      final tipW = fingerW * (extension == 2 ? 0.80 : 0.88);

      final path = _fingerPath(base, angle, length, fingerW, tipW);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);

      if (extension == 2) {
        _drawNail(canvas, base, angle, length, tipW, side);
      }
    }

    // --- pulgar -----------------------------------------------------------
    final thumbExtension = current.thumb;
    if (thumbExtension > 0 && !current.thumbAcross) {
      final thumbBase = Offset(-palmW * 0.44, knuckleY + palmH * 0.42);
      final thumbAngle = -math.pi / 3.1 - current.spread * math.pi / 7;
      final thumbLen = palmH * (thumbExtension == 2 ? 0.82 : 0.50);
      final thumbW = fingerW * 1.25;

      final path = _fingerPath(
        thumbBase,
        thumbAngle,
        thumbLen,
        thumbW,
        thumbW * 0.82,
      );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      if (thumbExtension == 2) {
        _drawNail(canvas, thumbBase, thumbAngle, thumbLen, thumbW * 0.82, side);
      }
    }

    // --- palma ------------------------------------------------------------
    final palm = _palmPath(palmW, palmH, knuckleY);
    canvas.drawPath(palm, fill);

    // Volumen: la base del pulgar y el borde del meñique quedan más oscuros.
    canvas.save();
    canvas.clipPath(palm);
    canvas.drawCircle(
      Offset(-palmW * 0.30, knuckleY + palmH * 0.62),
      palmW * 0.34,
      Paint()..color = tones.shade.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(palmW * 0.38, knuckleY + palmH * 0.55),
      palmW * 0.22,
      Paint()..color = tones.shade.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(palmW * 0.02, knuckleY + palmH * 0.28),
      palmW * 0.26,
      Paint()..color = tones.light.withValues(alpha: 0.55),
    );
    canvas.restore();
    canvas.drawPath(palm, stroke);

    // --- pulgar cruzado sobre la palma ------------------------------------
    if (thumbExtension > 0 && current.thumbAcross) {
      final thumbBase = Offset(-palmW * 0.42, knuckleY + palmH * 0.30);
      final thumbLen = palmW * (thumbExtension == 2 ? 0.78 : 0.58);
      final thumbW = fingerW * 1.2;

      final path = _fingerPath(
        thumbBase,
        math.pi / 2,
        thumbLen,
        thumbW,
        thumbW * 0.85,
      );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    canvas.restore();

    if (current.hasMotion) _drawMotion(canvas, center, side);
  }

  /// Dedo cónico con la punta redondeada y un ligero abombamiento lateral.
  Path _fingerPath(
    Offset base,
    double angle,
    double length,
    double wBase,
    double wTip,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final perp = Offset(-dir.dy, dir.dx);
    final tip = base + dir * length;

    final b1 = base + perp * (wBase / 2);
    final b2 = base - perp * (wBase / 2);
    final t1 = tip + perp * (wTip / 2);
    final t2 = tip - perp * (wTip / 2);
    final beyond = tip + dir * (wTip * 0.66);
    final bulge = wBase * 0.08;

    return Path()
      ..moveTo(b1.dx, b1.dy)
      ..quadraticBezierTo(
        (b1.dx + t1.dx) / 2 + perp.dx * bulge,
        (b1.dy + t1.dy) / 2 + perp.dy * bulge,
        t1.dx,
        t1.dy,
      )
      ..quadraticBezierTo(beyond.dx, beyond.dy, t2.dx, t2.dy)
      ..quadraticBezierTo(
        (b2.dx + t2.dx) / 2 - perp.dx * bulge,
        (b2.dy + t2.dy) / 2 - perp.dy * bulge,
        b2.dx,
        b2.dy,
      )
      ..close();
  }

  void _drawNail(
    Canvas canvas,
    Offset base,
    double angle,
    double length,
    double tipW,
    double side,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final nailCenter = base + dir * (length - tipW * 0.30);

    canvas.save();
    canvas.translate(nailCenter.dx, nailCenter.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: tipW * 0.56,
          height: tipW * 0.70,
        ),
        Radius.circular(tipW * 0.26),
      ),
      Paint()..color = tones.nail,
    );
    canvas.restore();
  }

  /// Silueta de la palma: ancha en los nudillos, con la base del pulgar
  /// abultada a la izquierda y estrechándose hacia la muñeca.
  Path _palmPath(double w, double h, double topY) {
    final left = -w / 2;
    final right = w / 2;
    final bottomY = topY + h;

    return Path()
      ..moveTo(left, topY + h * 0.12)
      ..cubicTo(
        left - w * 0.09,
        topY + h * 0.48,
        left + w * 0.01,
        bottomY - h * 0.04,
        left + w * 0.17,
        bottomY,
      )
      ..quadraticBezierTo(0, bottomY + h * 0.07, right - w * 0.17, bottomY)
      ..cubicTo(
        right - w * 0.01,
        bottomY - h * 0.06,
        right + w * 0.04,
        topY + h * 0.46,
        right,
        topY + h * 0.12,
      )
      ..quadraticBezierTo(0, topY - h * 0.07, left, topY + h * 0.12)
      ..close();
  }

  void _drawMotion(Canvas canvas, Offset center, double side) {
    final arrow = Paint()
      ..color = tones.line.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.018
      ..strokeCap = StrokeCap.round;

    final start = Offset(center.dx + side * 0.24, center.dy + side * 0.26);
    final end = Offset(center.dx + side * 0.32, center.dy + side * 0.40);

    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          center.dx + side * 0.36,
          center.dy + side * 0.32,
          end.dx,
          end.dy,
        ),
      arrow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(end.dx - side * 0.05, end.dy - side * 0.03)
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx - side * 0.01, end.dy - side * 0.06),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant _HandPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.tones != tones ||
      oldDelegate.background != background;
}
