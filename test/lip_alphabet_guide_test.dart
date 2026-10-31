import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/lip_reading/lip_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/lip_alphabet_guide_screen.dart';
import 'package:flutter_code4all/ui/core/ui/lip_painters.dart';

const _spanishAlphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';

/// Quita las tildes, pero no la virgulilla: la Ñ es otra letra.
String _plain(String text) => text
    .toUpperCase()
    .replaceAll('Á', 'A')
    .replaceAll('É', 'E')
    .replaceAll('Í', 'I')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U');

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(900, 1400),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.getTheme(mode: AppThemeMode.light),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
        child: const LipAlphabetGuideScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('el abecedario de la guía', () {
    test('están las 27 letras, cada una una sola vez', () {
      final letters = lipAlphabet.map((entry) => entry.letter).toList()..sort();
      final expected = _spanishAlphabet.split('')..sort();

      expect(letters, expected);
    });

    test('cada letra explica cómo se hace', () {
      for (final entry in lipAlphabet) {
        expect(entry.how.length, greaterThan(30), reason: entry.letter);
      }
    });

    test('la palabra de ejemplo contiene la letra que se practica', () {
      for (final entry in lipAlphabet) {
        expect(
          _plain(entry.example),
          contains(entry.letter),
          reason: '«${entry.example}» no tiene ${entry.letter}',
        );
      }
    });

    test('solo promete que la cámara reconoce lo que distingue', () {
      final readable = lipAlphabet
          .where((entry) => entry.cameraReads)
          .map((entry) => entry.letter)
          .toSet();

      expect(readable, {'A', 'E', 'I', 'O', 'U', 'M', 'B', 'P', 'V'});
    });

    test('lo que se ve bien coincide con lo que la guía dice que se ve', () {
      for (final entry in lipAlphabet) {
        if (entry.visibility == LipVisibility.hidden) {
          expect(entry.cameraReads, isFalse, reason: entry.letter);
        }
      }
    });
  });

  group('LipAlphabetGuideScreen', () {
    testWidgets('dice qué es y lista el abecedario para saltar a cada letra', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Las letras con la boca'), findsOneWidget);
      expect(find.textContaining('Muchas consonantes'), findsOneWidget);
      for (final letter in _spanishAlphabet.split('')) {
        expect(
          find.bySemanticsLabel('Ir a la letra $letter'),
          findsOneWidget,
          reason: letter,
        );
      }
    });

    testWidgets('el abecedario va en orden, con la Ñ después de la N', (
      tester,
    ) async {
      await _open(tester);

      final labels = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .map((button) => (button.child! as Text).data)
          .toList();

      expect(labels.join(), _spanishAlphabet);
    });

    testWidgets('tocar una letra lleva a su explicación', (tester) async {
      await _open(tester);
      final explanation = find.textContaining('En Colombia suena como la S');
      expect(tester.getTopLeft(explanation).dy, greaterThan(1400));

      await tester.tap(find.bySemanticsLabel('Ir a la letra Z'));
      await tester.pumpAndSettle();

      final top = tester.getTopLeft(explanation).dy;
      expect(top, greaterThan(0));
      expect(top, lessThan(1400));
    });

    testWidgets('dibuja la boca de cada letra', (tester) async {
      await _open(tester, size: const Size(900, 16000));

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<MouthPosePainter>();

      expect(painters, hasLength(lipAlphabet.length));
    });

    testWidgets('dice cuánto se ve cada letra con palabras, no solo color', (
      tester,
    ) async {
      await _open(tester, size: const Size(900, 16000));

      expect(find.text('Se ve bien'), findsWidgets);
      expect(find.text('Se ve, pero se parece a otras'), findsWidgets);
      expect(find.text('Casi no se ve'), findsWidgets);
      expect(find.text('La cámara la reconoce'), findsNWidgets(9));
    });

    testWidgets('con la letra al 200 % en un móvil pequeño no se desborda', (
      tester,
    ) async {
      await _open(tester, size: const Size(320, 700), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.byType(LipAlphabetGuideScreen), findsOneWidget);
    });
  });
}
