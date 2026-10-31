import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/lip_painters.dart';

/// El manual de las letras con la boca: cómo se hace cada una y cuánto se ve.
///
/// Es una pantalla y no un PDF porque así funciona sin cámara y sin servidor,
/// respeta el tamaño de letra elegido y el lector de pantalla la lee entera.
class LipAlphabetGuideScreen extends StatefulWidget {
  const LipAlphabetGuideScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const LipAlphabetGuideScreen(),
  );

  @override
  State<LipAlphabetGuideScreen> createState() => _LipAlphabetGuideScreenState();
}

class _LipAlphabetGuideScreenState extends State<LipAlphabetGuideScreen> {
  /// Para saltar a una letra desde el abecedario de arriba.
  final Map<String, GlobalKey> _letterKeys = {
    for (final entry in lipAlphabet) entry.letter: GlobalKey(),
  };

  void _jumpTo(String letter) {
    final target = _letterKeys[letter]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 250),
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <LipLetterGroup>[];
    for (final entry in lipAlphabet) {
      if (!groups.contains(entry.group)) groups.add(entry.group);
    }
    final alphabetical = [...lipAlphabet.map((entry) => entry.letter)]
      ..sort(_alphabeticalOrder);

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: const GlobalAppBarWidget(title: 'Las letras con la boca'),
      body: SafeArea(
        child: Column(
          children: [
            const AccessibilityToolbar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: AppMetrics.pagePadding(constraints.maxWidth),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppMetrics.maxContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _Introduction(),
                            const SizedBox(height: AppMetrics.gap),
                            _LetterIndex(
                              letters: alphabetical,
                              onSelected: _jumpTo,
                            ),
                            for (final group in groups) ...[
                              const SizedBox(height: AppMetrics.sectionGap),
                              _GroupHeader(group: group),
                              for (final entry in lipAlphabet.where(
                                (entry) => entry.group == group,
                              )) ...[
                                const SizedBox(height: AppMetrics.gap),
                                _LetterCard(
                                  key: _letterKeys[entry.letter],
                                  entry: entry,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El orden del abecedario, con la Ñ después de la N.
int _alphabeticalOrder(String a, String b) {
  int position(String letter) =>
      letter == 'Ñ' ? 'N'.codeUnitAt(0) * 2 + 1 : letter.codeUnitAt(0) * 2;
  return position(a) - position(b);
}

class _Introduction extends StatelessWidget {
  const _Introduction();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Text(
        'Así se hace cada letra del abecedario con la boca. Ponte frente a un '
        'espejo o enciende la cámara y compara. Habla despacio: cada letra '
        'describe el sonido dentro de una palabra, no el nombre de la letra. '
        'Muchas consonantes se hacen por dentro y casi no se ven: es normal, '
        'también le pasa a quien lee labios todos los días.',
        style: TextStyle(fontSize: 16, height: 1.45, color: colors.onSurface),
      ),
    );
  }
}

/// El abecedario en orden, para encontrar una letra sin saber su grupo.
class _LetterIndex extends StatelessWidget {
  const _LetterIndex({required this.letters, required this.onSelected});

  final List<String> letters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = AppContrast.readableOn(
      context.messageColors.infoForeground,
      context.colorScheme.surface,
      AppContrast.text,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final letter in letters)
          Semantics(
            label: 'Ir a la letra $letter',
            button: true,
            excludeSemantics: true,
            child: OutlinedButton(
              onPressed: () => onSelected(letter),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent),
                minimumSize: const Size(
                  AppMetrics.minTapTarget,
                  AppMetrics.minTapTarget,
                ),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(letter),
            ),
          ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final LipLetterGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            group.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          group.summary,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({super.key, required this.entry});

  final LipLetter entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final messages = context.messageColors;
    final tone = messages.tone(switch (entry.visibility) {
      LipVisibility.clear => MessageThemeTone.success,
      LipVisibility.similar => MessageThemeTone.info,
      LipVisibility.hidden => MessageThemeTone.warning,
    });
    final toneText = AppContrast.readableOn(
      tone.foreground,
      tone.background,
      AppContrast.text,
    );

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Column(
              children: [
                Text(
                  entry.letter,
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: messages.infoBackground,
                    borderRadius: BorderRadius.circular(AppMetrics.radius),
                  ),
                  child: CustomPaint(painter: MouthPosePainter(entry.pose)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppMetrics.gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Para el lector de pantalla: el dibujo y la letra grande no
                // se leen, así que la tarjeta empieza diciendo cuál es.
                Semantics(
                  label: 'Letra ${entry.letter}',
                  child: const SizedBox.shrink(),
                ),
                Text(
                  entry.how,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pruébala con: «${entry.example}»',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(
                      text: entry.visibility.label,
                      background: tone.background,
                      foreground: toneText,
                    ),
                    if (entry.cameraReads)
                      _Tag(
                        text: 'La cámara la reconoce',
                        background: messages.infoBackground,
                        foreground: AppContrast.readableOn(
                          messages.infoForeground,
                          messages.infoBackground,
                          AppContrast.text,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppMetrics.pillRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
