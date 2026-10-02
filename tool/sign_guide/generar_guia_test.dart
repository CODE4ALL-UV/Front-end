// Genera la guía en PDF del alfabeto para la cámara de «Lee mi mano».
//
//     flutter test tool/sign_guide/generar_guia_test.dart
//
// Escribe assets/docs/guia_alfabeto_camara.pdf. Hay que volver a generarla si
// cambia la forma de alguna letra en lib/domain/models/sign_language/
// hand_alphabet.dart: los dibujos y el texto salen de esa misma tabla, la que
// usa la cámara para reconocer, así que nunca se contradicen.
//
// Va como prueba porque así se dibuja con el motor de Flutter, el mismo que
// pinta las manos en la app. No está en test/: no corre con `flutter test`.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_letter_guide.dart';
import 'package:flutter_code4all/ui/core/ui/hand_sign_painter_widget.dart';

const _output = 'assets/docs/guia_alfabeto_camara.pdf';

const _blue = PdfColor.fromInt(0xFF1565C0);
const _ink = PdfColor.fromInt(0xFF1A1A1A);
const _muted = PdfColor.fromInt(0xFF4F4F4F);
const _tint = PdfColor.fromInt(0xFFE3F2FD);
const _warnInk = PdfColor.fromInt(0xFF8A5000);
const _warnTint = PdfColor.fromInt(0xFFFFF3E0);

Future<Uint8List> _drawHand(HandShape shape) async {
  const side = 320.0;
  final recorder = ui.PictureRecorder();
  HandPainter(
    shape: shape,
    tones: SkinTones.warm,
    background: const Color(0xFFE3F2FD),
  ).paint(Canvas(recorder), const Size(side, side));
  final image = await recorder.endRecording().toImage(
    side.toInt(),
    side.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

pw.Font _font(String file) =>
    pw.Font.ttf(ByteData.sublistView(File(file).readAsBytesSync()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera la guía del alfabeto en PDF', () async {
    final hands = <String, Uint8List>{
      for (final entry in signAlphabet.entries)
        entry.key: await _drawHand(entry.value),
    };

    final doc = pw.Document(
      title: 'Guía del alfabeto para la cámara de Code4All',
      author: 'Code4All, Universidad del Valle',
      subject: 'Cómo hacer cada letra para que «Lee mi mano» la reconozca',
      keywords: 'alfabeto manual, dactilología, cámara, Code4All',
      creator: 'Code4All',
      theme: pw.ThemeData.withFont(
        base: _font('assets/fonts/Roboto/Roboto-Regular.ttf'),
        bold: _font('assets/fonts/Roboto/Roboto-Bold.ttf'),
      ),
    );

    pw.Widget footer(pw.Context context) => pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Code4All · Guía del alfabeto para la cámara · '
        'página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    );

    pw.Widget heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: _blue,
        ),
      ),
    );

    pw.Widget bullet(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            child: pw.Text('•', style: const pw.TextStyle(color: _blue)),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
            ),
          ),
        ],
      ),
    );

    // --- Primera página: cómo usar la cámara y cómo leer las fichas -------
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 30),
        footer: footer,
        build: (context) => [
          pw.Text(
            'Guía del alfabeto para la cámara',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Cómo hacer cada letra para que «Lee mi mano» de Code4All la '
            'reconozca.',
            style: const pw.TextStyle(fontSize: 13, color: _muted),
          ),
          heading('Antes de empezar'),
          bullet(
            'Usa una sola mano y que se vea entera, con la muñeca dentro de '
            'la imagen.',
          ),
          bullet(
            'Dedos hacia arriba y la muñeca abajo. Solo la P y la Q se hacen '
            'con la mano apuntando hacia abajo.',
          ),
          bullet(
            'Ponte a un brazo de distancia de la cámara: que la mano se vea '
            'grande, no como un punto al fondo.',
          ),
          bullet(
            'Busca buena luz de frente y, si puedes, un fondo liso. A '
            'contraluz la cámara no distingue los dedos.',
          ),
          bullet(
            'Sostén cada letra quieta unos ${SignLetterGuide.holdSeconds} '
            'segundos. La cámara mira una foto cada medio segundo y la letra '
            'cuenta cuando sale igual ${SignLetterGuide.framesToAccept} veces '
            'seguidas.',
          ),
          bullet(
            'Para repetir una letra, como la «rr» de «perro», baja la mano un '
            'momento y vuelve a subirla.',
          ),
          heading('Cómo leer cada ficha'),
          bullet(
            'Estirado: el dedo recto. Doblado a medias, en gancho: doblado '
            'por la mitad, sin cerrarlo. Recogido: cerrado sobre la palma.',
          ),
          bullet(
            'El pulgar se mide por lo que se aparta del costado de la mano: '
            'pegado, un poco separado o bien separado hacia el lado. A veces '
            'va cruzado por delante de la palma.',
          ),
          bullet(
            'Si la cámara lee otra letra, la ficha dice qué corregir. Es la '
            'misma pista que da la pantalla mientras practicas.',
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _warnTint,
              border: pw.Border.all(color: _warnInk, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Esta guía describe lo que la cámara de Code4All sabe medir: '
              'una aproximación del alfabeto manual letra a letra. No es una '
              'referencia de Lengua de Señas Colombiana, que tiene gramática '
              'propia y no se construye deletreando. La J, la Ñ y la Z llevan '
              'movimiento y no se pueden reconocer en una foto. Para la '
              'cámara se hacen igual: '
              '${SignLetterGuide.identicalPairs.map((p) => '${p.$1} y ${p.$2}').join(', ')}.',
              style: const pw.TextStyle(
                fontSize: 10.5,
                color: _warnInk,
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );

    // --- Una ficha por letra, dos por fila --------------------------------
    pw.Widget card(String letter) {
      final shape = signAlphabet[letter]!;
      final same = SignLetterGuide.identicalTo(letter);
      final similar = SignLetterGuide.similarTo(letter);

      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              children: [
                pw.Text(
                  letter,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: _blue,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Image(pw.MemoryImage(hands[letter]!), width: 78),
              ],
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final step in SignLetterGuide.steps(letter))
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        step,
                        style: const pw.TextStyle(fontSize: 8.6),
                      ),
                    ),
                  if (shape.hasMotion)
                    _note(
                      'Lleva movimiento: la cámara no la reconoce. Escríbela '
                      'con el teclado.',
                    ),
                  if (same.isNotEmpty)
                    _note(
                      'Para la cámara es igual que la ${same.join(' y la ')}: '
                      'no las distingue.',
                    ),
                  for (final other in similar.take(2))
                    _hint(
                      'Si lee $other: '
                      '${SignLetterGuide.fixWhenReadAs(letter, other)}',
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final letters = SignLetterGuide.letters;
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 26),
        footer: footer,
        build: (context) => [
          pw.Text(
            'Las letras, una a una',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 10),
          for (var i = 0; i < letters.length; i += 2)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: card(letters[i])),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: i + 1 < letters.length
                        ? card(letters[i + 1])
                        : pw.SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final bytes = await doc.save();
    File(_output)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    expect(File(_output).lengthSync(), greaterThan(10000));
  });
}

pw.Widget _note(String text) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 4),
  padding: const pw.EdgeInsets.all(5),
  decoration: pw.BoxDecoration(
    color: _warnTint,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(
    text,
    style: const pw.TextStyle(fontSize: 8.2, color: _warnInk),
  ),
);

pw.Widget _hint(String text) => pw.Container(
  margin: const pw.EdgeInsets.only(top: 4),
  padding: const pw.EdgeInsets.all(5),
  decoration: pw.BoxDecoration(
    color: _tint,
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Text(text, style: const pw.TextStyle(fontSize: 8.2, color: _blue)),
);
