import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';

import 'hand_sign_painter_widget.dart';

/// La seña de una letra, en pequeño.
///
/// Si el equipo docente deja una foto en `assets/sign_language/letras`, manda
/// esa. Mientras no la haya, se dibuja la mano en código. Es la misma regla
/// que ya seguía el panel de señas, y el motivo es el mismo: una foto de una
/// persona señando enseña mejor que un esquema, pero un esquema enseña más
/// que un hueco.
///
/// Lo que se ve aquí es **dactilología** —deletrear letra a letra— y no
/// Lengua de Señas Colombiana, que tiene señas y gramática propias. Las
/// letras que llevan movimiento (J, Z, Ñ) no se pueden mostrar quietas, así
/// que se marcan para no dar a entender que se hacen con la mano parada.
class SignLetterIcon extends StatefulWidget {
  const SignLetterIcon({super.key, required this.letter, this.size = 28});

  /// La letra, tal cual: 'A', 'Ñ'…
  final String letter;
  final double size;

  @override
  State<SignLetterIcon> createState() => _SignLetterIconState();
}

class _SignLetterIconState extends State<SignLetterIcon> {
  String? _assetPath;

  @override
  void initState() {
    super.initState();
    _lookUpAsset();
  }

  @override
  void didUpdateWidget(SignLetterIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter != widget.letter) _lookUpAsset();
  }

  Future<void> _lookUpAsset() async {
    final index = SignAssetIndex.instance;
    await index.ensureLoaded();
    if (!mounted) return;
    setState(() => _assetPath = index.letterAsset(widget.letter));
  }

  @override
  Widget build(BuildContext context) {
    final path = _assetPath;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: path != null
          ? Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => _drawing(context),
            )
          : _drawing(context),
    );
  }

  Widget _drawing(BuildContext context) {
    final shape = signAlphabet[widget.letter.toUpperCase()];
    if (shape == null) return const SizedBox.shrink();

    return CustomPaint(
      painter: HandPainter(
        shape: shape,
        tones: SkinTones.warm,
        background: Colors.transparent,
      ),
    );
  }
}
