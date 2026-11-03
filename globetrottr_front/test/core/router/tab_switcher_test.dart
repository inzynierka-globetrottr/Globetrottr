import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/tab_switcher.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    int current,
    TabTransition transition,
  ) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.from(
        AppPalette.light,
        motion: AppMotion.standard.copyWith(tabTransition: transition),
      ),
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

  testWidgets('fade through: the old tab leaves before the new one comes', (
    tester,
  ) async {
    await show(tester, 0, TabTransition.fadeThrough);
    await show(tester, 1, TabTransition.fadeThrough);
    await tester.pump(AppMotion.standard.long * 0.2);

    expect(opacityOf(tester, 'first'), inExclusiveRange(0, 1));
    expect(opacityOf(tester, 'second'), 0);

    await tester.pump(AppMotion.standard.long * 0.5);
    expect(opacityOf(tester, 'first'), 0);
    expect(opacityOf(tester, 'second'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(opacityOf(tester, 'second'), 1);
  });

  testWidgets('instant: the new tab is there at once', (tester) async {
    await show(tester, 0, TabTransition.instant);
    await show(tester, 1, TabTransition.instant);
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(opacityOf(tester, 'second'), 1);
  });

  testWidgets('fade in: the old tab is gone at once, the new one appears', (
    tester,
  ) async {
    await show(tester, 0, TabTransition.fadeIn);
    await show(tester, 1, TabTransition.fadeIn);
    await tester.pump(AppMotion.standard.short ~/ 2);

    expect(find.text('first'), findsNothing);
    expect(opacityOf(tester, 'second'), inExclusiveRange(0, 1));
  });

  test('the theme uses the chosen transition for deeper screens', () {
    for (final transition in DeeperTransition.values) {
      final theme = AppTheme.from(
        AppPalette.light,
        motion: AppMotion.standard.copyWith(deeperTransition: transition),
      );
      expect(theme.pageTransitionsTheme, transition.pageTransitions);
    }
  });
}
