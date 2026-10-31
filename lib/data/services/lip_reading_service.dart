import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../domain/models/lip_reading/lip_reading_models.dart';
import 'api_service.dart';

/// Por qué no se pudo leer la boca.
enum LipFailureKind {
  /// No se pudo hablar con el servidor.
  offline,

  /// El servidor está, pero la lectura de labios no está instalada.
  unavailable,

  /// La foto no valía: formato raro, vacía o demasiado pesada.
  badImage,

  /// Cualquier otra cosa.
  unknown,
}

/// Un intento de lectura que no salió bien.
class LipReadingException implements Exception {
  LipReadingException(this.kind, this.message);

  final LipFailureKind kind;

  /// Explicación en castellano, lista para enseñar en pantalla.
  final String message;

  @override
  String toString() => message;
}

/// Pregunta al servidor qué hace la boca en una foto y qué palabra se dijo en
/// un clip. Toda la lectura de labios está allí, en Python.
///
/// **Privacidad.** Las fotos van al backend propio, se analizan en memoria y se
/// descartan; no se guardan ni se mandan a ningún servicio de terceros.
class LipReadingService {
  LipReadingService({ApiService? api, http.Client? client})
    : _api = api ?? ApiService(),
      _client = client ?? http.Client();

  final ApiService _api;
  final http.Client _client;

  /// Cuánto se espera por una foto suelta. Si tarda más, la siguiente ya viene
  /// de camino y esperar solo acumula retraso.
  static const Duration frameTimeout = Duration(seconds: 8);

  /// Cuánto se espera por un clip: son decenas de fotos y, en un servidor
  /// gratuito, cada una tarda bastante más que en un equipo normal.
  static const Duration clipTimeout = Duration(seconds: 45);

  bool? _available;

  /// Por qué no estaba disponible en la última comprobación.
  LipFailureKind? lastFailure;

  /// Lo que explicó el servidor, si lo explicó. Es técnico: sirve a quien
  /// mantiene el servidor, no al estudiante.
  String? lastReason;

  /// Las palabras que el servidor sabe leer.
  List<String> words = const [];

  /// Dice si el servidor puede leer labios, sin llegar a mandarle ninguna foto.
  ///
  /// Se consulta antes de encender la cámara, para no pedirle permiso a nadie
  /// y fallar después.
  Future<bool> isAvailable({bool refresh = false}) async {
    if (_available != null && !refresh) return _available!;

    lastFailure = null;
    lastReason = null;
    try {
      final response = await _client
          .get(Uri.parse(_api.buildUrl('/api/lips/status')))
          .timeout(frameTimeout);

      if (response.statusCode != 200) {
        lastFailure = LipFailureKind.unavailable;
        return _available = false;
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map) {
        lastFailure = LipFailureKind.unavailable;
        return _available = false;
      }

      words = [
        for (final word in body['words'] as List? ?? const [])
          if (word is String) word,
      ];

      final available = body['available'] == true;
      if (!available) {
        lastFailure = LipFailureKind.unavailable;
        final reason = body['reason'];
        if (reason is String && reason.trim().isNotEmpty) lastReason = reason;
      }
      return _available = available;
    } catch (_) {
      lastFailure = LipFailureKind.offline;
      return _available = false;
    }
  }

  /// Manda una foto y devuelve cómo está la boca. Sin cara, devuelve null: lo
  /// normal mientras la persona se coloca.
  Future<LipFrame?> readFrame(Uint8List frame, {double? neutralWidth}) async {
    if (frame.isEmpty) {
      throw LipReadingException(
        LipFailureKind.badImage,
        'La foto llegó vacía.',
      );
    }

    final body = await _send(
      '/api/lips/landmarks',
      [_part('file', frame)],
      neutralWidth,
      frameTimeout,
    );
    return parseFrame(body);
  }

  /// Manda las fotos de una palabra, en orden, y devuelve lo que se leyó.
  Future<LipWordReading> readClip(
    List<Uint8List> frames, {
    double? neutralWidth,
  }) async {
    if (frames.isEmpty) {
      return const LipWordReading(problem: LipReadingProblem.tooShort);
    }

    final body = await _send(
      '/api/lips/read',
      [for (final frame in frames) _part('files', frame)],
      neutralWidth,
      clipTimeout,
    );
    return parseClip(body);
  }

  http.MultipartFile _part(String field, Uint8List bytes) =>
      http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: 'frame.jpeg',
        contentType: MediaType('image', 'jpeg'),
      );

  Future<String> _send(
    String path,
    List<http.MultipartFile> files,
    double? neutralWidth,
    Duration timeout,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse(_api.buildUrl(path)))
      ..files.addAll(files);
    if (neutralWidth != null) {
      request.fields['neutral_width'] = neutralWidth.toStringAsFixed(4);
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw LipReadingException(
        LipFailureKind.offline,
        'No se pudo conectar con el servidor para leer los labios.',
      );
    }

    if (response.statusCode == 503) {
      throw LipReadingException(
        LipFailureKind.unavailable,
        'La lectura de labios no está disponible en el servidor.',
      );
    }
    if (response.statusCode == 413 || response.statusCode == 415) {
      throw LipReadingException(
        LipFailureKind.badImage,
        'El servidor no aceptó las fotos de la cámara.',
      );
    }
    if (response.statusCode != 200) {
      throw LipReadingException(
        LipFailureKind.unknown,
        'El servidor respondió ${response.statusCode} al leer los labios.',
      );
    }

    // Con `response.body`, «sí» llegaría como «sÃ­»: el servidor no declara la
    // codificación en la cabecera y `http` supone entonces latin1.
    return utf8.decode(response.bodyBytes);
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Se cuenta igual que una respuesta con otra forma.
    }
    throw LipReadingException(
      LipFailureKind.unknown,
      'El servidor devolvió algo que no se entiende.',
    );
  }

  /// Separado de la llamada para poder probarlo sin red.
  static LipFrame? parseFrame(String body) {
    final face = _decode(body)['face'];
    return face is Map<String, dynamic> ? LipFrame.fromJson(face) : null;
  }

  /// Separado de la llamada para poder probarlo sin red.
  static LipWordReading parseClip(String body) =>
      LipWordReading.fromJson(_decode(body));

  void dispose() => _client.close();
}
