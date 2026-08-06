import 'package:flutter/material.dart';

class AccessibilityTextScaleController extends ChangeNotifier {
  static final AccessibilityTextScaleController global =
      AccessibilityTextScaleController();

  double _scale = 1.0;

  double get scale => _scale;
  bool get isEnabled => _scale != 1.0;

  void setScale(double scale) {
    final nextScale = scale.clamp(0.9, 2.0);
    if ((_scale - nextScale).abs() < 0.001) {
      return;
    }

    _scale = nextScale;
    notifyListeners();
  }

  void increase() {
    final next = (_scale + 0.1).clamp(0.9, 2.0);
    if (next != _scale) {
      _scale = next;
      notifyListeners();
    }
  }

  void decrease() {
    final next = (_scale - 0.1).clamp(0.9, 2.0);
    if (next != _scale) {
      _scale = next;
      notifyListeners();
    }
  }

  void reset() => setScale(1.0);
}

class AccessibilityTextScaleScope
    extends InheritedNotifier<AccessibilityTextScaleController> {
  const AccessibilityTextScaleScope({
    super.key,
    required AccessibilityTextScaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccessibilityTextScaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AccessibilityTextScaleScope>();
    return scope?.notifier ?? AccessibilityTextScaleController.global;
  }
}
