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

  test('the scale follows the transitions of the mock-up', () {
    const motion = AppMotion.standard;

    expect(motion.short, const Duration(milliseconds: 200));
    expect(motion.medium, const Duration(milliseconds: 240));
    expect(motion.long, const Duration(milliseconds: 280));
    expect(motion.curve, Curves.ease);
  });

  test('reduced motion makes every change instant', () {
    final reduced = AppMotion.standard.reduced;

    expect(reduced.short, Duration.zero);
    expect(reduced.medium, Duration.zero);
    expect(reduced.long, Duration.zero);
    expect(reduced.flight, Duration.zero);
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
