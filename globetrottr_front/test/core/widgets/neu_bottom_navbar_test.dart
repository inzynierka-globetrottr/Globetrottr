import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
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

  testWidgets('the pill and the label colours are on the new tab at once', (
    tester,
  ) async {
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
    Color? colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    await tester.pumpWidget(navbar(NavbarItem.map));
    await tester.pumpAndSettle();

    await tester.pumpWidget(navbar(NavbarItem.friends));
    await tester.pump();

    expect(
      pill(tester).contains(tester.getCenter(find.text('Friends'))),
      isTrue,
    );
    expect(colorOf('Friends'), AppPalette.light.onAccent);
    expect(colorOf('Map'), AppPalette.light.textMuted);
  });

  testWidgets('the bar takes the map shadow at once', (tester) async {
    Widget navbar({required bool overMap}) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: NeuBottomNavbar(
          activeItem: NavbarItem.map,
          overMap: overMap,
          onSelect: (_) {},
        ),
      ),
    );
    final shadows = AppShadows.fromPalette(AppPalette.light);
    List<NeoShadow> barShadows() =>
        tester.widget<NeuSurface>(find.byType(NeuSurface).first).shadows;
    await tester.pumpWidget(navbar(overMap: false));
    await tester.pumpAndSettle();
    expect(barShadows(), shadows.raised(NeoDepth.xl));

    await tester.pumpWidget(navbar(overMap: true));
    await tester.pump();

    expect(barShadows(), shadows.mapNav);
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
