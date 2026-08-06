import 'package:flutter/widgets.dart';

class VisualThemeController extends InheritedWidget {
  VisualThemeController({
    super.key,
    required bool isDarkTheme,
    required this.onThemeChanged,
    required super.child,
  }) : isDarkTheme = isDarkTheme;

  final bool isDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  static final ValueNotifier<bool> globalThemeNotifier = ValueNotifier<bool>(
    false,
  );

  static VisualThemeController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VisualThemeController>();
  }

  static void updateTheme(bool isDarkTheme) {
    globalThemeNotifier.value = isDarkTheme;
  }

  @override
  bool updateShouldNotify(covariant VisualThemeController oldWidget) {
    return isDarkTheme != oldWidget.isDarkTheme;
  }
}
