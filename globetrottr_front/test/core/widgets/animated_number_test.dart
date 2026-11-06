import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';

void main() {
  String format(double? value) => value == null ? '—' : '${value.round()}';

  Future<void> show(
    WidgetTester tester,
    double? value, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: AnimatedNumber(value: value, format: format),
      ),
    ),
  );

  testWidgets('the first value is shown at once', (tester) async {
    await show(tester, 40);

    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('a new value is counted up to', (tester) async {
    await show(tester, 0);
    await show(tester, 100);

    await tester.pump(AppMotion.standard.long ~/ 2);
    final halfway = int.parse(tester.widget<Text>(find.byType(Text)).data!);
    expect(halfway, inExclusiveRange(0, 100));

    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('an unknown value is shown as such and is not counted from', (
    tester,
  ) async {
    await show(tester, null);
    expect(find.text('—'), findsOneWidget);

    await show(tester, 70);
    expect(find.text('70'), findsOneWidget);
  });

  testWidgets('without animations a new value is shown at once', (
    tester,
  ) async {
    await show(tester, 0, disableAnimations: true);
    await show(tester, 100, disableAnimations: true);
    await tester.pump();

    expect(find.text('100'), findsOneWidget);
  });
}
