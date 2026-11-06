import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/router/tab_switcher.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:go_router/go_router.dart';

/// The four tabs under one navigation, one branch per [NavbarItem] in its
/// order. Each tab keeps its screen and its place while another is shown.
StatefulShellRoute appTabs(List<StatefulShellBranch> branches) {
  assert(
    branches.length == NavbarItem.values.length,
    'One branch per navigation item',
  );
  return StatefulShellRoute(
    builder: (context, state, shell) => AppShell(shell: shell),
    navigatorContainerBuilder: (context, shell, tabs) =>
        TabSwitcher(current: shell.currentIndex, tabs: tabs),
    branches: branches,
  );
}

/// The tabs with the navigation floating over them. Back on any tab but the
/// map returns to the map; on the map it leaves the app.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final active = NavbarItem.values[shell.currentIndex];
    return PopScope(
      canPop: active == NavbarItem.map,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(NavbarItem.map.index);
      },
      child: Scaffold(
        // The tabs run on under the floating navigation; their padding
        // includes it.
        extendBody: true,
        body: shell,
        bottomNavigationBar: NeuBottomNavbar(
          activeItem: active,
          overMap: active == NavbarItem.map,
          onSelect: (item) => shell.goBranch(item.index),
        ),
      ),
    );
  }
}
