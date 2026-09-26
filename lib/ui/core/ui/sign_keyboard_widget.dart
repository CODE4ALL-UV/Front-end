import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

import 'accessibility_announcer_widget.dart';
import 'sign_letter_icon_widget.dart';

/// Teclado con el alfabeto manual: cada tecla lleva su letra y su seña.
///
/// Sustituye al teclado del sistema en lugar de ponerse encima. No es una
/// preferencia estética: ni los navegadores ni Android dejan dibujar por
/// encima del teclado del sistema, así que mostrarlo a la vez significaría
/// que entre los dos se comen la pantalla y que en móvil las teclas quedan
/// inservibles. Sustituyéndolo se comporta igual en web y en el teléfono.
///
/// Lo que muestra es **dactilología** —deletrear letra a letra— y no Lengua
/// de Señas Colombiana. Las letras que se hacen con movimiento (J, Z, Ñ)
/// llevan un aviso, porque una imagen quieta no puede enseñarlas y callarlo
/// sería enseñarlas mal.
class SignKeyboard extends StatelessWidget {
  const SignKeyboard({
    super.key,
    required this.controller,
    this.onDone,
    this.maxHeight,
  });

  final TextEditingController controller;

  /// Qué hacer con la tecla de terminar. Sin esto, no se muestra.
  final VoidCallback? onDone;

  /// Tope de alto. Sin él ocupa lo que necesite.
  final double? maxHeight;

  /// El orden del abecedario español, que es el que se está aprendiendo.
  static const List<String> letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  void _insert(BuildContext context, String text) {
    final value = controller.value;
    final selection = value.selection;

    // Un campo al que todavía no se ha tocado no tiene cursor: se escribe al
    // final, que es donde la persona espera que aparezca.
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;

    final updated = value.text.replaceRange(start, end, text);

    controller.value = value.copyWith(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );

    HapticFeedback.selectionClick();
  }

  void _backspace(BuildContext context) {
    final value = controller.value;
    final selection = value.selection;

    if (value.text.isEmpty) return;

    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;

    if (start != end) {
      controller.value = value.copyWith(
        text: value.text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
        composing: TextRange.empty,
      );
    } else {
      if (start == 0) return;
      controller.value = value.copyWith(
        text: value.text.replaceRange(start - 1, start, ''),
        selection: TextSelection.collapsed(offset: start - 1),
        composing: TextRange.empty,
      );
    }

    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appSemanticColors.infoBackground,
        border: Border(top: BorderSide(color: appSemanticColors.infoBorder)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final letter in letters)
                      _LetterKey(
                        letter: letter,
                        hasMotion: signAlphabet[letter]?.hasMotion ?? false,
                        onPressed: () => _insert(context, letter),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ActionKey(
                        label: 'Espacio',
                        icon: Icons.space_bar,
                        onPressed: () => _insert(context, ' '),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _ActionKey(
                        label: 'Borrar',
                        icon: Icons.backspace_outlined,
                        onPressed: () => _backspace(context),
                      ),
                    ),
                    if (onDone != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: _ActionKey(
                          label: 'Listo',
                          icon: Icons.keyboard_hide,
                          onPressed: () {
                            announceForAccessibility(
                              context,
                              'Teclado de señas cerrado',
                            );
                            onDone!();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Una tecla: la letra grande y debajo cómo se hace con la mano.
class _LetterKey extends StatelessWidget {
  const _LetterKey({
    required this.letter,
    required this.hasMotion,
    required this.onPressed,
  });

  final String letter;

  /// La letra se hace con un movimiento, así que la seña dibujada es sólo el
  /// punto de partida.
  final bool hasMotion;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Semantics(
      button: true,
      label: hasMotion
          ? 'Letra $letter. Se hace con movimiento.'
          : 'Letra $letter',
      child: ExcludeSemantics(
        child: Material(
          color: appColorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 54,
              constraints: const BoxConstraints(
                minHeight: AppMetrics.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appSemanticColors.infoBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SignLetterIcon(letter: letter, size: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        letter,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: appSemanticColors.infoText,
                        ),
                      ),
                      if (hasMotion) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.animation,
                          size: 11,
                          color: appSemanticColors.warningText,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Espacio, borrar y terminar.
class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final appSemanticColors = Theme.of(
      context,
    ).extension<ActivityThemeColors>()!;

    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, overflow: TextOverflow.ellipsis),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, AppMetrics.minTapTarget),
            foregroundColor: appSemanticColors.infoText,
          ),
        ),
      ),
    );
  }
}
