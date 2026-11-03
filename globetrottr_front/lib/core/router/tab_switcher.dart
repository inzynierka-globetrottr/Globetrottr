import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/router/tab_visibility.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// Keeps every tab alive and shows the [current] one, changing tabs as the
/// motion of the theme says. Hidden tabs are neither drawn nor ticking.
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({super.key, required this.current, required this.tabs});

  final int current;
  final List<Widget> tabs;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher>
    with SingleTickerProviderStateMixin {
  /// The share of a fade through in which the old tab fades out.
  static const _fadeOutShare = 0.35;
  static const _fadeThroughGrowth = 0.04;

  late final AnimationController _switch = AnimationController(
    vsync: this,
    value: 1,
  );
  int? _leaving;
  Animation<double> _leavingOpacity = kAlwaysCompleteAnimation;
  Animation<double> _comingOpacity = kAlwaysCompleteAnimation;
  Animation<double> _comingScale = kAlwaysCompleteAnimation;
  final List<CurvedAnimation> _parts = [];

  @override
  void didUpdateWidget(TabSwitcher old) {
    super.didUpdateWidget(old);
    if (old.current == widget.current) return;
    final motion = context.motion;
    final transition = motion.tabTransition;
    final duration = switch (transition) {
      TabTransition.fadeThrough => motion.long,
      TabTransition.fadeIn => motion.short,
      TabTransition.instant => Duration.zero,
    };
    _prepare(transition, motion.curve);
    final leaving = _leaving = transition == TabTransition.fadeThrough
        ? old.current
        : null;
    _switch.duration = duration;
    _switch.forward(from: 0).whenCompleteOrCancel(() {
      // A quicker next switch has taken over.
      if (mounted && _leaving == leaving && !_switch.isAnimating) {
        setState(() => _leaving = null);
      }
    });
  }

  void _prepare(TabTransition transition, Curve curve) {
    _disposeParts();
    Animation<double> part(double from, double to) {
      final curved = CurvedAnimation(
        parent: _switch,
        curve: Interval(from, to, curve: curve),
      );
      _parts.add(curved);
      return curved;
    }

    switch (transition) {
      case TabTransition.fadeThrough:
        _leavingOpacity = ReverseAnimation(part(0, _fadeOutShare));
        final coming = part(_fadeOutShare, 1);
        _comingOpacity = coming;
        _comingScale = Tween(
          begin: 1 - _fadeThroughGrowth,
          end: 1.0,
        ).animate(coming);
      case TabTransition.fadeIn:
        _comingOpacity = part(0, 1);
        _comingScale = kAlwaysCompleteAnimation;
      case TabTransition.instant:
        _comingOpacity = kAlwaysCompleteAnimation;
        _comingScale = kAlwaysCompleteAnimation;
    }
  }

  void _disposeParts() {
    for (final part in _parts) {
      part.dispose();
    }
    _parts.clear();
  }

  @override
  void dispose() {
    _disposeParts();
    _switch.dispose();
    super.dispose();
  }

  // The tree keeps its shape whatever is animated, so no tab loses its
  // state.
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < widget.tabs.length; i++)
        Offstage(
          offstage: i != widget.current && i != _leaving,
          child: TickerMode(
            enabled: i == widget.current,
            child: TabActive(
              active: i == widget.current,
              child: FadeTransition(
                opacity: i == widget.current
                    ? _comingOpacity
                    : (i == _leaving
                          ? _leavingOpacity
                          : kAlwaysCompleteAnimation),
                child: ScaleTransition(
                  scale: i == widget.current
                      ? _comingScale
                      : kAlwaysCompleteAnimation,
                  child: widget.tabs[i],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
