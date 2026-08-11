import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rebuilds when the global theme notifier changes', (
    tester,
  ) async {
    VisualThemeController.globalThemeNotifier.value = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VisualThemeBuilder(
            builder: (context, isDarkTheme) {
              return Text(isDarkTheme ? 'dark' : 'light');
            },
          ),
        ),
      ),
    );

    expect(find.text('light'), findsOneWidget);

    VisualThemeController.globalThemeNotifier.value = true;
    await tester.pump();

    expect(find.text('dark'), findsOneWidget);
  });

  testWidgets(
    'resolves the inherited theme before falling back to the notifier',
    (tester) async {
      VisualThemeController.globalThemeNotifier.value = false;

      await tester.pumpWidget(
        MaterialApp(
          home: VisualThemeController(
            isDarkTheme: true,
            onThemeChanged: (_) {},
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return Text(
                    VisualThemeController.resolveIsDark(context)
                        ? 'dark'
                        : 'light',
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('dark'), findsOneWidget);
    },
  );
}
