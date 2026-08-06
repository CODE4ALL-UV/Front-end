import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale.dart';

void main() {
  test('increase and decrease change the text scale step by step', () {
    final controller = AccessibilityTextScaleController();

    expect(controller.scale, 1.0);

    controller.increase();
    expect(controller.scale, closeTo(1.1, 0.0001));

    controller.increase();
    expect(controller.scale, closeTo(1.2, 0.0001));

    controller.decrease();
    expect(controller.scale, closeTo(1.1, 0.0001));

    controller.reset();
    expect(controller.scale, closeTo(1.0, 0.0001));
  });
}
