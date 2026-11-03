import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> pumpNavbar(WidgetTester tester) async {
    Widget page(NavbarItem item) =>
        Scaffold(bottomNavigationBar: NeuBottomNavbar(activeItem: item));
    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        for (final item in NavbarItem.values)
          GoRoute(path: item.route, builder: (_, _) => page(item)),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('shows every tab with its label', (tester) async {
    await pumpNavbar(tester);

    for (final label in ['Map', 'Quests', 'Friends', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('only the active tab is filled with the accent', (tester) async {
    await pumpNavbar(tester);

    final filled = tester
        .widgetList<NeuSurface>(find.byType(NeuSurface))
        .where((s) => s.color == AppPalette.light.accent);
    expect(filled, hasLength(1));
    expect(
      find.descendant(
        of: find.byWidget(filled.single),
        matching: find.text('Map'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tab opens its screen', (tester) async {
    final router = await pumpNavbar(tester);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, NavbarItem.friends.route);
  });
}
