import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/router/tab_visibility.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// Keeps every tab alive and shows the [current] one. A newly chosen tab
/// fades in, as a deeper screen does, while the old one is gone at once.
/// Hidden tabs are neither drawn nor ticking.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({super.key, required this.current, required this.tabs});

  final int current;
  final List<Widget> tabs;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(TabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.current == widget.current) return;
    _fade.duration = context.motion.short;
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  // The tree keeps its shape whatever is shown, so no tab loses its state.
  @override
  Widget build(BuildContext context) {
    final opacity = _fade.drive(CurveTween(curve: context.motion.curve));
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          Offstage(
            offstage: i != widget.current,
            child: TickerMode(
              enabled: i == widget.current,
              child: TabActive(
                active: i == widget.current,
                child: FadeTransition(
                  opacity: i == widget.current
                      ? opacity
                      : kAlwaysCompleteAnimation,
                  child: widget.tabs[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
