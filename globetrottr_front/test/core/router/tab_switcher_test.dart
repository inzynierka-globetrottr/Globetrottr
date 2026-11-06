import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/tab_switcher.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    int current, {
    AppMotion motion = AppMotion.standard,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.from(AppPalette.light, motion: motion),
      home: TabSwitcher(
        current: current,
        tabs: const [Text('first'), Text('second')],
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('the old tab is gone at once and the new one fades in', (
    tester,
  ) async {
    await show(tester, 0);
    await show(tester, 1);
    await tester.pump(AppMotion.standard.short ~/ 2);

    expect(find.text('first'), findsNothing);
    expect(opacityOf(tester, 'second'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'second'), 1);
  });

  testWidgets('with animations turned off the new tab is there at once', (
    tester,
  ) async {
    await show(tester, 0, motion: AppMotion.standard.reduced);
    await show(tester, 1, motion: AppMotion.standard.reduced);
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(opacityOf(tester, 'second'), 1);
  });
}
