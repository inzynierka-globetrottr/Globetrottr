import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/unfold_transition.dart';

/// Unfolds downwards and fades in [child] when it first appears, so what
/// lies below slides away instead of jumping. Removing it is instant.
class UnfoldIn extends StatefulWidget {
  const UnfoldIn({super.key, required this.child});

  final Widget child;

  @override
  State<UnfoldIn> createState() => _UnfoldInState();
}

class _UnfoldInState extends State<UnfoldIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(vsync: this);
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _appear,
    curve: Curves.linear,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _appear.duration = motion.medium;
    _curved.curve = motion.curve;
    if (_appear.isDismissed) _appear.forward();
  }

  @override
  void dispose() {
    _curved.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UnfoldTransition(
    sizeFactor: _curved,
    fitWidth: true,
    child: FadeTransition(opacity: _curved, child: widget.child),
  );
}
