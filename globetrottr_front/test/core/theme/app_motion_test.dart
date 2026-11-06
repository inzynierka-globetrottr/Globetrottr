import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

void main() {
  Future<BuildContext> pumpWith(
    WidgetTester tester, {
    ThemeData? theme,
    bool disableAnimations = false,
  }) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  test('the scale is quicker than the transitions of the mock-up', () {
    const motion = AppMotion.standard;

    expect(motion.short, const Duration(milliseconds: 150));
    expect(motion.medium, const Duration(milliseconds: 180));
    expect(motion.long, const Duration(milliseconds: 220));
    expect(motion.curve, Curves.ease);
  });

  test('a button is raised again at once after its shortest hold', () {
    expect(AppMotion.standard.pressRise, Duration.zero);
    expect(AppMotion.standard.pressHold, isNot(Duration.zero));
  });

  test('a tab fades in and a deeper screen comes in at once', () {
    expect(AppMotion.standard.tabTransition, TabTransition.fadeIn);
    expect(AppMotion.standard.deeperTransition, DeeperTransition.instant);
  });

  testWidgets('an instant deeper screen is shown without a transition', (
    tester,
  ) async {
    final builder = DeeperTransition.instant.pageTransitions.builders.values
        .toSet()
        .single;
    expect(builder.transitionDuration, Duration.zero);

    const page = SizedBox(key: ValueKey('page'));
    final route = MaterialPageRoute<void>(builder: (_) => page);
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(
      builder.buildTransitions(
        route,
        context,
        kAlwaysDismissedAnimation,
        kAlwaysDismissedAnimation,
        page,
      ),
      same(page),
    );
  });

  test('reduced motion makes every change instant', () {
    final reduced = AppMotion.standard.reduced;

    expect(reduced.short, Duration.zero);
    expect(reduced.medium, Duration.zero);
    expect(reduced.long, Duration.zero);
    expect(reduced.flight, Duration.zero);
    expect(reduced.landing, Duration.zero);
    expect(reduced.pressRise, Duration.zero);
  });

  test('reduced motion still shows a press, as it is not a movement', () {
    expect(AppMotion.standard.reduced.pressHold, AppMotion.standard.pressHold);
  });

  test('the app theme carries the motion', () {
    final theme = AppTheme.from(AppPalette.light);

    expect(theme.extension<AppMotion>(), AppMotion.standard);
  });

  testWidgets('widgets read the motion of the app theme', (tester) async {
    final context = await pumpWith(
      tester,
      theme: AppTheme.from(AppPalette.light),
    );

    expect(context.motion, AppMotion.standard);
  });

  testWidgets('without the app theme the standard motion is used', (
    tester,
  ) async {
    final context = await pumpWith(tester);

    expect(context.motion, AppMotion.standard);
  });

  testWidgets('the system setting that turns animations off is honoured', (
    tester,
  ) async {
    final context = await pumpWith(
      tester,
      theme: AppTheme.from(AppPalette.light),
      disableAnimations: true,
    );

    expect(context.motion, AppMotion.standard.reduced);
  });
}
