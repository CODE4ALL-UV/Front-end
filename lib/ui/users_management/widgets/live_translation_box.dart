import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/utils/external_url_opener.dart';

class LiveTranslationBox extends StatefulWidget {
  final String videoUrl;
  final String? backendUrl;
  const LiveTranslationBox({
    super.key,
    required this.videoUrl,
    this.backendUrl,
  });

  @override
  State<LiveTranslationBox> createState() => _LiveTranslationBoxState();
}

class _LiveTranslationBoxState extends State<LiveTranslationBox> {
  List<Map<String, dynamic>> _cues = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _startedAt;
  Timer? _timer;
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _loadCaptions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCaptions() async {
    final videoId = _extractVideoId(widget.videoUrl);
    if (videoId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No se pudo detectar el ID del video.';
      });
      return;
    }

    // Allow a sensible default when dotenv not configured during development.
    final backend =
        widget.backendUrl ??
        dotenv.env['BACKEND_URL'] ??
        'http://127.0.0.1:8000';

    try {
      final uri = Uri.parse(
        '$backend/api/youtube/captions',
      ).replace(queryParameters: {'video_id': videoId, 'target': 'es'});
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final cues = decoded['cues'] as List<dynamic>? ?? [];
        setState(() {
          _cues = cues.map<Map<String, dynamic>>((item) {
            final map = item as Map<String, dynamic>;
            return {
              'start': map['start'] ?? 0.0,
              'duration': map['duration'] ?? 0.0,
              'text': map['text'] ?? '',
              'translated': map['translated'],
            };
          }).toList();
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'No se pudieron cargar subtítulos (status ${res.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtube.com') ||
        uri.host.contains('www.youtube.com')) {
      return uri.queryParameters['v'];
    }
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return null;
  }

  Future<void> _openAndSync() async {
    await openExternalUrl(widget.videoUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Se abrió el video en una pestaña. Iniciando sincronía...',
        ),
      ),
    );
    if (_isLoading) await _loadCaptions();
    if (!mounted) return;
    if (_cues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontraron subtítulos para sincronizar.'),
        ),
      );
    }
    _startSync();
  }

  void _startSync() {
    _startedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _update(),
    );
    setState(() {});
  }

  void _stopSync() {
    _timer?.cancel();
    _startedAt = null;
    _currentIndex = null;
    setState(() {});
  }

  void _update() {
    if (_startedAt == null || _cues.isEmpty) return;
    final elapsed =
        DateTime.now().difference(_startedAt!).inMilliseconds / 1000.0;
    int? idx;
    for (var i = 0; i < _cues.length; i++) {
      final start = (_cues[i]['start'] as num).toDouble();
      final dur = (_cues[i]['duration'] as num).toDouble();
      if (elapsed >= start && elapsed < start + dur) {
        idx = i;
        break;
      }
    }
    if (idx != _currentIndex) {
      _currentIndex = idx;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (_startedAt == null)
            const Text(
              'Traducción en tiempo real',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Backend: ${dotenv.env['BACKEND_URL'] ?? widget.backendUrl ?? 'http://127.0.0.1:8000'}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          if (_startedAt != null)
            Expanded(
              child: Center(
                child: Text(
                  _currentIndex == null
                      ? ''
                      : (_cues[_currentIndex!]['translated'] ??
                            _cues[_currentIndex!]['text'] ??
                            ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          const SizedBox(height: 8),
          // show quick debug/count info about loaded cues
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Subtítulos: ${_cues.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Use Wrap so buttons flow on small widths instead of overflowing
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ElevatedButton.icon(
                onPressed: _openAndSync,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir y sincronizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _startedAt == null ? null : _stopSync,
                child: const Text('Detener'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _startedAt == null
                    ? null
                    : () {
                        _startedAt = DateTime.now();
                        setState(() {});
                      },
                child: const Text('Re-sincronizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
