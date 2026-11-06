import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/app_tabs.dart';
import 'package:globetrottr_front/core/router/tab_visibility.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GlobalKey<NavigatorState> root;
  late Map<String, int> shown;

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    root = GlobalKey<NavigatorState>();
    shown = {};
    StatefulShellBranch branch(
      String path, {
      List<RouteBase> routes = const [],
    }) => StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => _FakeTab(name: path, shown: shown),
          routes: routes,
        ),
      ],
    );
    final router = GoRouter(
      navigatorKey: root,
      initialLocation: '/map',
      routes: [
        appTabs([
          branch('/map'),
          branch(
            '/quests',
            routes: [
              GoRoute(
                path: 'history',
                parentNavigatorKey: root,
                builder: (_, _) => const Text('history'),
              ),
            ],
          ),
          branch('/friends'),
          branch('/profile'),
        ]),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('one navigation stays while the tabs change', (tester) async {
    await pumpApp(tester);
    final navbar = tester.element(find.byType(NeuBottomNavbar));

    await openTab(tester, 'Quests');

    expect(tester.element(find.byType(NeuBottomNavbar)), same(navbar));
  });

  testWidgets('a tab keeps its state while another one is shown', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('/map +'));
    await tester.pump();
    expect(find.text('/map 1'), findsOneWidget);

    await openTab(tester, 'Quests');
    await openTab(tester, 'Map');

    expect(find.text('/map 1'), findsOneWidget);
  });

  testWidgets('a chosen tab is shown and the hidden one is not drawn', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Quests'));
    await tester.pump();

    expect(find.text('/map 0'), findsNothing);
    expect(find.text('/quests 0'), findsOneWidget);
  });

  testWidgets('a tab learns each time it is shown again', (tester) async {
    await pumpApp(tester);
    expect(shown['/map'], 1);

    await openTab(tester, 'Quests');
    await openTab(tester, 'Map');

    expect(shown['/map'], 2);
    expect(shown['/quests'], 1);
  });

  testWidgets('a tab is not told again when a deeper screen closes', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    await openTab(tester, 'Quests');

    router.go('/quests/history');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(shown['/quests'], 1);
  });

  testWidgets('back on another tab returns to the map', (tester) async {
    final router = await pumpApp(tester);
    await openTab(tester, 'Friends');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/map');
  });

  testWidgets('a deeper screen covers the navigation and back goes up', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    await openTab(tester, 'Quests');

    router.go('/quests/history');
    await tester.pumpAndSettle();
    expect(find.byType(NeuBottomNavbar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '/quests');
    expect(find.byType(NeuBottomNavbar), findsOneWidget);
  });
}

class _FakeTab extends StatefulWidget {
  const _FakeTab({required this.name, required this.shown});

  final String name;
  final Map<String, int> shown;

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> with TabVisibility {
  int _taps = 0;

  @override
  void onTabShown() =>
      widget.shown.update(widget.name, (n) => n + 1, ifAbsent: () => 1);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${widget.name} $_taps'),
        TextButton(
          onPressed: () => setState(() => _taps++),
          child: Text('${widget.name} +'),
        ),
      ],
    ),
  );
}
