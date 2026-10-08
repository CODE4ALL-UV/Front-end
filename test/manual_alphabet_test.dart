import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';

/// El manual web deletrea con las mismas manos que la app.
///
/// `web/manual.html` es HTML suelto, sin Flutter, así que no puede importar
/// [signAlphabet]: lleva la tabla copiada en JavaScript (`const SIGNS`). Si se
/// corrige una letra en la app y no en el manual, el manual enseñaría otra
/// mano para la misma letra.
void main() {
  test('la tabla del manual coincide con signAlphabet', () {
    final html = File('web/manual.html').readAsStringSync();
    final start = html.indexOf('const SIGNS = {');
    expect(start, isNot(-1), reason: 'El manual ya no tiene «const SIGNS».');
    final table = html.substring(start, html.indexOf('};', start));

    final entry = RegExp(
      r"'?([A-ZÑ])'?:\{f:\[(\d),(\d),(\d),(\d),(\d)\]([^}]*)\}",
    );
    final manual = <String, String>{
      for (final m in entry.allMatches(table))
        m.group(1)!: _describe(
          [for (var i = 2; i <= 6; i++) int.parse(m.group(i)!)],
          spread: double.parse(
            RegExp(r'spread:([\d.]+)').firstMatch(m.group(7)!)?.group(1) ?? '0',
          ),
          across: m.group(7)!.contains('across:1'),
          motion: m.group(7)!.contains('motion:1'),
          down: m.group(7)!.contains('down:1'),
          crossed: m.group(7)!.contains('crossed:1'),
        ),
    };

    final app = <String, String>{
      for (final e in signAlphabet.entries)
        e.key: _describe(
          [e.value.thumb, ...e.value.fingers],
          spread: e.value.spread,
          across: e.value.thumbAcross,
          motion: e.value.hasMotion,
          down: e.value.pointsDown,
          crossed: e.value.crossed,
        ),
    };

    expect(manual, app);
  });
}

String _describe(
  List<int> fingers, {
  required double spread,
  required bool across,
  required bool motion,
  required bool down,
  required bool crossed,
}) => [
  'dedos ${fingers.join()}',
  'apertura $spread',
  if (across) 'pulgar cruzado',
  if (motion) 'con movimiento',
  if (down) 'hacia abajo',
  if (crossed) 'índice y corazón cruzados',
].join(', ');
