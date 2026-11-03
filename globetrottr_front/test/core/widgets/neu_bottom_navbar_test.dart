import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
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

  Rect pill(WidgetTester tester) => tester.getRect(
    find.byWidget(
      tester
          .widgetList<NeuSurface>(find.byType(NeuSurface))
          .singleWhere((s) => s.color == AppPalette.light.accent),
    ),
  );

  testWidgets('the accent pill sits under the active tab', (tester) async {
    await pumpNavbar(tester);

    expect(pill(tester).contains(tester.getCenter(find.text('Map'))), isTrue);
    expect(
      pill(tester).contains(tester.getCenter(find.text('Quests'))),
      isFalse,
    );
  });

  testWidgets('the pill slides to a newly active tab', (tester) async {
    Widget navbar(NavbarItem item) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: NeuBottomNavbar(
          activeItem: item,
          onSelect: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(navbar(NavbarItem.friends));
    await tester.pumpAndSettle();
    final end = pill(tester).left;
    expect(
      pill(tester).contains(tester.getCenter(find.text('Friends'))),
      isTrue,
    );

    await tester.pumpWidget(navbar(NavbarItem.map));
    await tester.pumpAndSettle();
    final start = pill(tester).left;

    await tester.pumpWidget(navbar(NavbarItem.friends));
    await tester.pump(AppMotion.standard.short ~/ 2);
    expect(pill(tester).left, inExclusiveRange(start, end));
  });

  testWidgets('keeps a gap above the system gesture bar', (tester) async {
    Future<double> gapFor(double systemBar) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(bottom: systemBar)),
            child: Scaffold(
              bottomNavigationBar: NeuBottomNavbar(
                activeItem: NavbarItem.map,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NeuSurface).first);
      final screen = tester.getSize(find.byType(Scaffold)).height;
      return screen - bar.bottom - systemBar;
    }

    expect(await gapFor(24), NeuBottomNavbar.gapAboveSystemBar);
    expect(await gapFor(0), NeuBottomNavbar.minBottomMargin);
  });

  testWidgets('tapping a tab opens its screen', (tester) async {
    final router = await pumpNavbar(tester);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, NavbarItem.friends.route);
  });
}
