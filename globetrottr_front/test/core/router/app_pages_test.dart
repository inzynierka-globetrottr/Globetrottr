import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/app_pages.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

void main() {
  /// Where the screen below is drawn while a deeper screen comes over it.
  Future<Rect> belowWhileCovered(
    WidgetTester tester, {
    required Page<void> Function(BuildContext, GoRouterState, Widget) below,
    required DeeperTransition transition,
    required TargetPlatform platform,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              below(context, state, const Center(child: Text('below'))),
          routes: [
            GoRoute(
              path: 'deeper',
              pageBuilder: (context, state) =>
                  deeperPage(context, state, const Text('deeper')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.from(
          AppPalette.light,
          motion: AppMotion.standard.copyWith(deeperTransition: transition),
        ).copyWith(platform: platform),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    router.go('/deeper');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final rect = tester.getRect(find.text('below'));
    await tester.pumpAndSettle();
    return rect;
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final transition in DeeperTransition.values) {
      testWidgets(
        'under ${transition.name} on ${platform.name} a fading screen moves '
        'aside like a screen built by the theme',
        (tester) async {
          final fading = await belowWhileCovered(
            tester,
            below: fadePage,
            transition: transition,
            platform: platform,
          );
          final themed = await belowWhileCovered(
            tester,
            below: deeperPage,
            transition: transition,
            platform: platform,
          );

          expect(fading, themed);
        },
      );
    }
  }

  testWidgets('the screen below is really moved, not left in place', (
    tester,
  ) async {
    final rest = await belowWhileCovered(
      tester,
      below: fadePage,
      transition: DeeperTransition.rise,
      platform: TargetPlatform.android,
    );
    final covered = await belowWhileCovered(
      tester,
      below: fadePage,
      transition: DeeperTransition.platform,
      platform: TargetPlatform.android,
    );

    expect(covered.left, lessThan(rest.left));
  });
}
