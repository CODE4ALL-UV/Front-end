import 'dart:convert';
import 'package:http/http.dart' as http;

enum TranslateProvider { google, deepl }

class TranslateService {
  final TranslateProvider provider;
  final String apiKey;

  TranslateService({required this.provider, required this.apiKey});

  /// Translate a list of texts to target language (eg. 'es').
  /// Returns translations in the same order.
  Future<List<String>> translateBatch(List<String> texts, String target) async {
    if (texts.isEmpty) return [];
    switch (provider) {
      case TranslateProvider.google:
        return _googleTranslate(texts, target);
      case TranslateProvider.deepl:
        return _deeplTranslate(texts, target);
    }
  }

  Future<List<String>> _googleTranslate(
    List<String> texts,
    String target,
  ) async {
    // Google Cloud Translate v2 REST API
    // Requires API key with Cloud Translation enabled.
    final uri = Uri.https(
      'translation.googleapis.com',
      '/language/translate/v2',
    );
    // The API accepts multiple q parameters for batching
    final request = {'key': apiKey, 'target': target};

    // Build query with multiple q entries
    final queryParameters = Map<String, dynamic>.from(request);
    for (var t in texts) {
      queryParameters.putIfAbsent('q', () => <String>[]);
    }

    // Unfortunately `http` package doesn't allow repeated keys easily with Map,
    // so we build the Uri manually.
    final sb = StringBuffer();
    sb.write('${uri.toString()}?key=$apiKey&target=$target');
    for (var t in texts) {
      sb.write('&q=${Uri.encodeQueryComponent(t)}');
    }

    final res = await http.post(Uri.parse(sb.toString()));
    if (res.statusCode != 200) {
      throw Exception('Google Translate error: ${res.statusCode} ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final translations =
        (data?['translations'] as List<dynamic>?)
            ?.map((t) => t['translatedText'] as String)
            .toList() ??
        [];
    return translations;
  }

  Future<List<String>> _deeplTranslate(
    List<String> texts,
    String target,
  ) async {
    // DeepL API: https://api.deepl.com/v2/translate
    final uri = Uri.https('api.deepl.com', '/v2/translate');
    // DeepL accepts multiple text= params
    final sb = StringBuffer();
    sb.write(
      '${uri.toString()}?auth_key=${Uri.encodeQueryComponent(apiKey)}&target_lang=${Uri.encodeQueryComponent(target.toUpperCase())}',
    );
    for (var t in texts) {
      sb.write('&text=${Uri.encodeQueryComponent(t)}');
    }
    final res = await http.post(Uri.parse(sb.toString()));
    if (res.statusCode != 200) {
      throw Exception('DeepL Translate error: ${res.statusCode} ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final translations =
        (body['translations'] as List<dynamic>?)
            ?.map((t) => t['text'] as String)
            .toList() ??
        [];
    return translations;
  }
}
