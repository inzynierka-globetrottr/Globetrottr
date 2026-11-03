import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_motion_provider.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/debug/animations/animations_screen.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  Future<void> show(WidgetTester tester, {Widget? replaceWith}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: replaceWith ?? const AnimationsScreen(),
        ),
      ),
    );
  }

  testWidgets('a control changes the value shown', (tester) async {
    await show(tester);
    await tester.scrollUntilVisible(find.text('42%'), 300);
    expect(find.text('42%'), findsOneWidget);

    await tester.ensureVisible(find.text('+10'));
    await tester.pump();
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();

    expect(find.text('52%'), findsOneWidget);
  });

  testWidgets('a chosen transition becomes the motion of the app', (
    tester,
  ) async {
    await show(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AnimationsScreen)),
    );

    await tester.tap(find.text(TabTransition.fadeIn.name));
    await tester.tap(find.text(DeeperTransition.rise.name));
    await tester.pump();

    final motion = container.read(appMotionProvider);
    expect(motion.tabTransition, TabTransition.fadeIn);
    expect(motion.deeperTransition, DeeperTransition.rise);
  });

  testWidgets('slow motion ends with the screen', (tester) async {
    await show(tester);
    await tester.tap(find.text('Slow motion x5'));
    await tester.pump();
    expect(timeDilation, AnimationsScreen.slowMotion);

    await show(tester, replaceWith: const SizedBox());
    expect(timeDilation, 1);
  });
}
