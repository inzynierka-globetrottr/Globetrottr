import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';

void main() {
  Future<void> show(WidgetTester tester, double fill) => tester.pumpWidget(
    Center(
      child: SizedBox.square(
        dimension: 60,
        child: ProgressRing(
          fill: fill,
          color: const Color(0xFF00897B),
          radiusRatio: 0.4,
          strokeRatio: 0.1,
        ),
      ),
    ),
  );

  double drawnFill(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ProgressRing),
        matching: find.byType(CustomPaint),
      ),
    );
    // The painter is private; its fill is what the ring shows.
    // ignore: avoid_dynamic_calls
    return (paint.painter! as dynamic).fill as double;
  }

  testWidgets('the first fill is drawn at once', (tester) async {
    await show(tester, 0.6);

    expect(drawnFill(tester), 0.6);
  });

  testWidgets('a new fill is reached gradually', (tester) async {
    await show(tester, 0.2);
    await show(tester, 0.8);

    await tester.pump(AppMotion.standard.long ~/ 2);
    expect(drawnFill(tester), inExclusiveRange(0.2, 0.8));

    await tester.pumpAndSettle();
    expect(drawnFill(tester), 0.8);
  });
}
