import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain/models/sign_language/hand_alphabet.dart';
import '../../domain/models/sign_language/hand_landmark_classifier.dart';
import 'api_service.dart';

/// Por qué no se pudo leer la mano.
enum SignFailureKind {
  /// No se pudo hablar con el servidor.
  offline,

  /// El servidor está, pero el reconocimiento no está instalado.
  unavailable,

  /// La foto no valía: formato raro, vacía o demasiado pesada.
  badImage,

  /// Cualquier otra cosa.
  unknown,
}

/// Un intento de lectura que no salió bien.
class SignRecognitionException implements Exception {
  SignRecognitionException(this.kind, this.message);

  final SignFailureKind kind;

  /// Explicación en castellano, lista para enseñar en pantalla.
  final String message;

  @override
  String toString() => message;
}

/// Lee la mano de una foto: pregunta al servidor dónde están los dedos y
/// deduce aquí qué letra es.
///
/// El reparto es a propósito. El servidor solo sabe de anatomía —devuelve los
/// 21 puntos de la mano— y la app es la que decide la letra, con la misma
/// tabla que usa para dibujarla. Así el alfabeto vive en un solo sitio y se
/// puede probar sin levantar nada.
///
/// **Privacidad.** La foto se manda al backend propio, se analiza en memoria y
/// se descarta; no se guarda ni se manda a ningún servicio de terceros. Aun
/// así, es la cámara de una persona: conviene pedir permiso de forma explícita
/// y no encenderla sola.
class SignRecognitionService {
  SignRecognitionService({ApiService? api, http.Client? client})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client();

  final ApiService _api;
  final http.Client _client;

  /// Cuánto se espera al servidor antes de darlo por perdido.
  ///
  /// Corto a propósito: si una foto tarda más, la siguiente ya viene de camino
  /// y esperar solo acumula retraso.
  static const Duration timeout = Duration(seconds: 8);

  bool? _available;

  /// Dice si el servidor puede reconocer manos, sin llegar a mandarle ninguna.
  ///
  /// Se consulta antes de encender la cámara, para no pedirle permiso a nadie
  /// y fallar después.
  Future<bool> isAvailable({bool refresh = false}) async {
    if (_available != null && !refresh) return _available!;

    try {
      final response = await _client
          .get(Uri.parse(_api.buildUrl('/api/signs/status')))
          .timeout(timeout);

      if (response.statusCode != 200) return _available = false;

      final body = jsonDecode(response.body);
      return _available = body is Map && body['available'] == true;
    } catch (_) {
      return _available = false;
    }
  }

  /// Manda una foto y devuelve qué letra parece estar haciendo la mano.
  ///
  /// [frame] son los bytes de una imagen JPEG o PNG.
  Future<SignReading> read(Uint8List frame, {String format = 'jpeg'}) async {
    if (frame.isEmpty) {
      throw SignRecognitionException(
        SignFailureKind.badImage,
        'La foto llegó vacía.',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(_api.buildUrl('/api/signs/landmarks')),
          )
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              frame,
              filename: 'frame.$format',
              contentType: MediaType('image', format),
            ),
          );

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw SignRecognitionException(
        SignFailureKind.offline,
        'No se pudo conectar con el servidor para leer la mano.',
      );
    }

    if (response.statusCode == 503) {
      throw SignRecognitionException(
        SignFailureKind.unavailable,
        'El reconocimiento de señas no está disponible en el servidor.',
      );
    }
    if (response.statusCode == 413 || response.statusCode == 415) {
      throw SignRecognitionException(
        SignFailureKind.badImage,
        'El servidor no aceptó la foto de la cámara.',
      );
    }
    if (response.statusCode != 200) {
      throw SignRecognitionException(
        SignFailureKind.unknown,
        'El servidor respondió ${response.statusCode} al leer la mano.',
      );
    }

    return parse(response.body);
  }

  /// Convierte la respuesta del servidor en una lectura.
  ///
  /// Separado de la llamada para poder probarlo sin red.
  static SignReading parse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw SignRecognitionException(
        SignFailureKind.unknown,
        'El servidor devolvió algo que no se entiende.',
      );
    }

    if (decoded is! Map || decoded['hands'] is! List) {
      throw SignRecognitionException(
        SignFailureKind.unknown,
        'El servidor devolvió algo que no se entiende.',
      );
    }

    final hands = decoded['hands'] as List;
    if (hands.isEmpty) return noHand;

    final first = hands.first;
    if (first is! Map || first['landmarks'] is! List) return noHand;

    final points = [
      for (final point in first['landmarks'] as List)
        if (point is Map<String, dynamic>) HandLandmark.fromJson(point),
    ];

    return HandLandmarkClassifier.classify(points);
  }

  /// Lo que se devuelve cuando no se ve ninguna mano.
  ///
  /// No es un error: lo normal es que la mayoría de fotos no tengan mano
  /// todavía, mientras la persona se coloca.
  static const SignReading noHand = SignReading(
    letter: null,
    confidence: 0,
    observed: HandShape(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 0),
  );

  void dispose() => _client.close();
}
