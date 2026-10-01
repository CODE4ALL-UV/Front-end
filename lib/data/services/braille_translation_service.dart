import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Lo que el servidor entendió de una celda.
class BrailleCellReading {
  const BrailleCellReading({
    required this.dots,
    required this.kind,
    required this.value,
    required this.spoken,
  });

  factory BrailleCellReading.fromJson(Map<String, dynamic> json) {
    return BrailleCellReading(
      dots: [for (final dot in json['dots'] as List? ?? const []) dot as int],
      kind: json['kind']?.toString() ?? 'unknown',
      value: json['value']?.toString() ?? '',
      spoken: json['spoken']?.toString() ?? '',
    );
  }

  final List<int> dots;

  /// letter, digit, punctuation, capital_sign, number_sign, space o unknown.
  final String kind;

  /// Lo que aporta al texto.
  final String value;

  /// Cómo decirlo en voz alta.
  final String spoken;

  bool get isUnknown => kind == 'unknown';
}

class BrailleTranslation {
  const BrailleTranslation({required this.text, required this.cells});

  factory BrailleTranslation.fromJson(Map<String, dynamic> json) {
    return BrailleTranslation(
      text: json['text']?.toString() ?? '',
      cells: [
        for (final cell in json['cells'] as List? ?? const [])
          BrailleCellReading.fromJson(cell as Map<String, dynamic>),
      ],
    );
  }

  final String text;
  final List<BrailleCellReading> cells;

  int get unrecognizedCount => cells.where((cell) => cell.isUnknown).length;
}

class BrailleTranslationException implements Exception {
  BrailleTranslationException(this.message);

  /// Explicación en castellano, lista para enseñar y para leer en voz alta.
  final String message;

  @override
  String toString() => message;
}

/// Manda las celdas del teclado Braille al backend y devuelve el texto.
///
/// La traducción la hace el servidor: aquí no hay tabla Braille. Cada celda
/// viaja como la lista de puntos levantados, y una celda vacía es un espacio.
class BrailleTranslationService {
  BrailleTranslationService({ApiService? api, http.Client? client})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client();

  final ApiService _api;
  final http.Client _client;

  static const Duration timeout = Duration(seconds: 8);

  Future<BrailleTranslation> translate(List<Set<int>> cells) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_api.buildUrl('/api/braille/translate')),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'cells': [for (final cell in cells) (cell.toList()..sort())],
            }),
          )
          .timeout(timeout);
    } catch (_) {
      throw BrailleTranslationException(
        'No se pudo conectar con el servidor para traducir el Braille.',
      );
    }

    if (response.statusCode != 200) {
      throw BrailleTranslationException(
        'El servidor no pudo traducir el Braille (error ${response.statusCode}).',
      );
    }

    return BrailleTranslation.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
