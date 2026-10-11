import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/users_management/widgets/live_translation_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LiveTranslationBox renders inside a scrollable layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 200),
                LiveTranslationBox(
                  videoUrl: 'https://www.youtube.com/watch?v=abc123',
                  backendUrl: 'http://127.0.0.1:8000',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Traducción en tiempo real'), findsOneWidget);
  });
}
