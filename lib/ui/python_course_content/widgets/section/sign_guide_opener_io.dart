import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// En el móvil la guía va dentro de la app: se lee y se entrega al visor de
/// PDF del sistema, que también permite guardarla o compartirla.
Future<bool> openSignGuide(String asset) async {
  try {
    final data = await rootBundle.load(asset);
    return Printing.sharePdf(
      bytes: data.buffer.asUint8List(),
      filename: 'guia_alfabeto_camara.pdf',
    );
  } catch (_) {
    return false;
  }
}
