import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:url_launcher/url_launcher_string.dart';

String? extractVideoId(String url) {
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

class YoutubeTranslatorPlayer extends StatefulWidget {
  final String videoUrl;
  final String? backendUrl;
  final String targetLang;

  const YoutubeTranslatorPlayer({
    super.key,
    required this.videoUrl,
    this.backendUrl,
    this.targetLang = 'es',
  });

  @override
  State<YoutubeTranslatorPlayer> createState() =>
      _YoutubeTranslatorPlayerState();
}

class _YoutubeTranslatorPlayerState extends State<YoutubeTranslatorPlayer> {
  late final ypf.YoutubePlayerController _controller;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _cues = [];
  String? _videoId;
  bool _showPlayer = false;
  DateTime? _externalStartedAt;
  Timer? _syncTimer;
  int? _currentCueIndex;

  @override
  void initState() {
    super.initState();
    _videoId = extractVideoId(widget.videoUrl);
    _controller = ypf.YoutubePlayerController(
      initialVideoId: _videoId ?? 'dQw4w9WgXcQ',
      flags: const ypf.YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        hideThumbnail: true,
        forceHD: false,
      ),
    );
    _loadCaptions();
  }

  @override
  void didUpdateWidget(covariant YoutubeTranslatorPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _videoId = extractVideoId(widget.videoUrl);
      _controller.load(_videoId ?? 'dQw4w9WgXcQ');
      _loadCaptions();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCaptions() async {
    if (_videoId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudo detectar el ID del video de YouTube.';
      });
      return;
    }

    final backendUrl = widget.backendUrl ?? dotenv.env['BACKEND_URL'];
    if (backendUrl == null || backendUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No hay URL del backend configurada.';
      });
      return;
    }

    try {
      final uri = Uri.parse('$backendUrl/api/youtube/captions').replace(
        queryParameters: {'video_id': _videoId!, 'target': widget.targetLang},
      );
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final cues = decoded['cues'] as List<dynamic>? ?? const [];
        if (!mounted) return;
        setState(() {
          // Map backend cue fields (`start`, `duration`, `text`, optional `translated`)
          _cues = cues.map<Map<String, dynamic>>((item) {
            final map = item as Map<String, dynamic>;
            return {
              'start': map['start'] ?? map['timestamp'] ?? 0.0,
              'duration': map['duration'] ?? 0.0,
              'text': map['text'] ?? '',
              'translated': map['translated'],
            };
          }).toList();
          _isLoading = false;
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron cargar los subtítulos.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar subtítulos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (_showPlayer)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ypf.YoutubePlayer(
                        controller: _controller,
                        showVideoProgressIndicator: true,
                      ),
                    )
                  else
                    Stack(
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Image.network(
                            'https://img.youtube.com/vi/${_videoId ?? "dQw4w9WgXcQ"}/hqdefault.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _showPlayer = true);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Reproducir dentro de la app'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Controls for external playback + live subtitle sync
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Open external video in a new tab/window, ensure captions loaded, then start syncing
                    final url = widget.videoUrl;
                    await _openExternalUrl(url);
                    // Ensure captions are loaded before starting sync (in case of slow network)
                    if (_isLoading) {
                      await _loadCaptions();
                    }
                    if (_cues.isNotEmpty) {
                      _startExternalSync();
                    } else {
                      // still start sync but show empty state (user can re-sync later)
                      _startExternalSync();
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir y sincronizar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _externalStartedAt == null
                      ? null
                      : _stopExternalSync,
                  child: const Text('Detener sincronía'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _externalStartedAt == null
                      ? null
                      : _resetSyncToNow,
                  child: const Text('Re-sincronizar ahora'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live subtitle display
            if (_externalStartedAt != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentSubtitleText(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),

            const SizedBox(height: 12),

            // Full subtitle list below
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _cues.length,
                      itemBuilder: (context, index) {
                        final cue = _cues[index];
                        final isActive = index == _currentCueIndex;
                        return Card(
                          color: isActive ? Colors.yellow[100] : null,
                          child: ListTile(
                            title: Text(
                              (cue['translated'] ?? cue['text']).toString(),
                            ),
                            subtitle: Text(
                              'Seg: ${cue['start']} - dur: ${cue['duration']}',
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

  Future<void> _openExternalUrl(String url) async {
    try {
      await launchUrlString(url, webOnlyWindowName: '_blank');
    } catch (e) {
      // ignore launch errors; syncing will continue regardless
    }
  }

  void _startExternalSync() {
    _externalStartedAt = DateTime.now();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateCurrentCue();
    });
    setState(() {});
  }

  void _stopExternalSync() {
    _syncTimer?.cancel();
    _externalStartedAt = null;
    _currentCueIndex = null;
    setState(() {});
  }

  void _resetSyncToNow() {
    _externalStartedAt = DateTime.now();
    setState(() {});
  }

  void _updateCurrentCue() {
    if (_externalStartedAt == null || _cues.isEmpty) return;
    final elapsed =
        DateTime.now().difference(_externalStartedAt!).inMilliseconds / 1000.0;
    int? newIndex;
    for (var i = 0; i < _cues.length; i++) {
      final start = (_cues[i]['start'] is num)
          ? (_cues[i]['start'] as num).toDouble()
          : double.tryParse((_cues[i]['start'] ?? '0').toString()) ?? 0.0;
      final dur = (_cues[i]['duration'] is num)
          ? (_cues[i]['duration'] as num).toDouble()
          : double.tryParse((_cues[i]['duration'] ?? '0').toString()) ?? 0.0;
      if (elapsed >= start && elapsed < start + dur) {
        newIndex = i;
        break;
      }
    }
    if (newIndex != _currentCueIndex) {
      _currentCueIndex = newIndex;
      setState(() {});
    }
  }

  String _currentSubtitleText() {
    if (_currentCueIndex == null) return '';
    final cue = _cues[_currentCueIndex!];
    return (cue['translated'] ?? cue['text'] ?? '').toString();
  }
}
