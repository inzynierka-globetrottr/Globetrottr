import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_motion_provider.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/debug/animations/animations_screen.dart';
import 'package:globetrottr_front/debug/animations/form_demos.dart';
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

    await tester.tap(find.text(TabTransition.fadeThrough.name));
    await tester.tap(find.text(DeeperTransition.rise.name));
    await tester.tap(find.text(MotionPace.mockup.name));
    await tester.tap(find.text(PressFeel.none.name));
    await tester.pump();

    final motion = container.read(appMotionProvider);
    expect(motion.tabTransition, TabTransition.fadeThrough);
    expect(motion.deeperTransition, DeeperTransition.rise);
    expect(motion.short, const Duration(milliseconds: 200));
    expect(motion.pressHold, Duration.zero);
  });

  testWidgets('clearing the field error demo empties the field too', (
    tester,
  ) async {
    await show(tester, replaceWith: const Scaffold(body: FieldErrorDemo()));

    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your login'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'explorer');
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your login'), findsNothing);
    expect(find.text('explorer'), findsNothing);
  });

  testWidgets('slow motion ends with the screen', (tester) async {
    await show(tester);
    await tester.scrollUntilVisible(find.text('Slow motion x5'), 300);
    await tester.tap(find.text('Slow motion x5'));
    await tester.pump();
    expect(timeDilation, AnimationsScreen.slowMotion);

    await show(tester, replaceWith: const SizedBox());
    expect(timeDilation, 1);
  });
}
