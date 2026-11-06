import 'package:flutter/widgets.dart';

/// Tells the screen of a tab whether its tab is the chosen one. A screen
/// outside the tabs counts as chosen.
class TabActive extends InheritedWidget {
  const TabActive({super.key, required this.active, required super.child});

  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabActive>()?.active ?? true;

  @override
  bool updateShouldNotify(TabActive old) => old.active != active;
}

/// For the screen of a tab, which stays alive while other tabs are shown:
/// [onTabShown] runs when it is shown first and every time its tab is
/// chosen again, so it can refresh its data as when it was built anew.
/// A deeper screen closing over it does not count, as the tab never left.
mixin TabVisibility<T extends StatefulWidget> on State<T> {
  bool _shown = false;

  /// Runs after the frame, so providers may be changed in it.
  void onTabShown();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TabActive.of(context);
    if (shown && !_shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onTabShown();
      });
    }
    _shown = shown;
  }
}
