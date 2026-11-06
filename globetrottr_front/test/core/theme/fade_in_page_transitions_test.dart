import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/theme/fade_in_page_transitions.dart';

void main() {
  final navigator = GlobalKey<NavigatorState>();
  final short = AppMotion.standard.short;

  Future<void> pumpBelow(
    WidgetTester tester, {
    AppMotion motion = AppMotion.standard,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: AppTheme.from(AppPalette.light, motion: motion),
        home: const Text('below'),
      ),
    );
    await tester.pumpAndSettle();
  }

  void pushDeeper() => navigator.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const Text('deeper')),
  );

  FadeTransition fadeOf(WidgetTester tester, String text) =>
      tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

  double opacityOf(WidgetTester tester, String text) =>
      fadeOf(tester, text).opacity.value;

  testWidgets('a new screen fades in on the page colour, covering the old '
      'one at once', (tester) async {
    await pumpBelow(tester);

    pushDeeper();
    await tester.pump();
    await tester.pump(short ~/ 2);

    expect(opacityOf(tester, 'deeper'), inExclusiveRange(0, 1));
    final backdrop = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byWidget(fadeOf(tester, 'deeper')),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(backdrop.color, AppPalette.light.background);

    await tester.pumpAndSettle();
    expect(find.text('below'), findsNothing);
    expect(opacityOf(tester, 'deeper'), 1);
  });

  testWidgets('going back, the screen is gone at once and the one below '
      'fades in', (tester) async {
    await pumpBelow(tester);
    pushDeeper();
    await tester.pumpAndSettle();

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(short ~/ 2);

    expect(find.text('deeper'), findsNothing);
    expect(opacityOf(tester, 'below'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'below'), 1);
  });

  testWidgets('with animations turned off a screen is there at once', (
    tester,
  ) async {
    await pumpBelow(tester, motion: AppMotion.standard.reduced);

    pushDeeper();
    await tester.pump();
    await tester.pump();

    expect(find.text('below'), findsNothing);
    expect(opacityOf(tester, 'deeper'), 1);
  });

  test('every platform fades in the short step of the scale', () {
    final builders = AppTheme.from(
      AppPalette.light,
    ).pageTransitionsTheme.builders;

    for (final platform in TargetPlatform.values) {
      final builder = builders[platform];
      expect(builder, isA<FadeInPageTransitionsBuilder>());
      expect(builder!.transitionDuration, short);
      expect(builder.reverseTransitionDuration, short);
    }
  });
}
