import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/youtube_translator_player.dart';

void main() {
  group('extractVideoId', () {
    test('extracts id from standard YouTube watch URLs', () {
      expect(
        extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts id from short youtu.be URLs', () {
      expect(extractVideoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });
  });
}
