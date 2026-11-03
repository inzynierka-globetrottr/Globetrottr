import 'package:flutter/widgets.dart';

/// For the screen of a tab, which stays alive while other tabs are shown:
/// [onTabShown] runs when it is shown first and every time it comes back,
/// so it can refresh its data as when it was built anew. A hidden tab has
/// its tickers turned off, which is how it is told apart.
mixin TabVisibility<T extends StatefulWidget> on State<T> {
  bool _shown = false;

  /// Runs after the frame, so providers may be changed in it.
  void onTabShown();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    if (shown && !_shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) onTabShown();
      });
    }
    _shown = shown;
  }
}
