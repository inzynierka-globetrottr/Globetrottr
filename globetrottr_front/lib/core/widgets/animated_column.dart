import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/unfold_transition.dart';

/// How a child added to an [AnimatedColumn] comes in.
enum ColumnEntrance {
  /// It unfolds, pushing what is below down.
  unfold,

  /// It fades in at its full size, for data arriving on an empty screen,
  /// where nothing below has to move.
  fade,
}

/// A column whose children unfold when they are added and fold away in
/// their place when removed, matched by their keys (children without one
/// are matched by position). The children it starts with are there at once.
/// The gap or [separator] before a child unfolds and folds with it.
class AnimatedColumn extends StatefulWidget {
  const AnimatedColumn({
    super.key,
    required this.children,
    this.spacing = 0,
    this.separator,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.entrance = ColumnEntrance.unfold,
  });

  final List<Widget> children;
  final double spacing;

  /// Drawn between two children, inside the [spacing].
  final Widget? separator;
  final CrossAxisAlignment crossAxisAlignment;

  /// How the children added from now on come in; leaving ones always fold.
  final ColumnEntrance entrance;

  @override
  State<AnimatedColumn> createState() => _AnimatedColumnState();
}

class _Entry {
  _Entry(this.key, this.child, this.controller, Curve curve)
    : curved = CurvedAnimation(parent: controller, curve: curve);

  final Key key;
  Widget child;
  final AnimationController controller;
  final CurvedAnimation curved;
  bool leaving = false;
  bool fadeOnly = false;

  void dispose() {
    curved.dispose();
    controller.dispose();
  }
}

class _AnimatedColumnState extends State<AnimatedColumn>
    with TickerProviderStateMixin {
  List<_Entry> _entries = [];

  static Key _keyOf(Widget child, int index) => child.key ?? ValueKey(index);

  _Entry _entry(Widget child, int index, {required bool shown}) {
    final motion = context.motion;
    final controller = AnimationController(
      vsync: this,
      duration: motion.medium,
      value: shown ? 1 : 0,
    );
    return _Entry(_keyOf(child, index), child, controller, motion.curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entries.isEmpty) {
      _entries = [
        for (var i = 0; i < widget.children.length; i++)
          _entry(widget.children[i], i, shown: true),
      ];
    }
    final duration = context.motion.medium;
    for (final entry in _entries) {
      entry.controller.duration = duration;
    }
  }

  @override
  void didUpdateWidget(AnimatedColumn old) {
    super.didUpdateWidget(old);
    final children = widget.children;
    final keys = {
      for (var i = 0; i < children.length; i++) _keyOf(children[i], i),
    };
    final byKey = {for (final entry in _entries) entry.key: entry};
    final next = <_Entry>[];
    var oldIndex = 0;

    // Leaving children stay where they were, before the next one kept.
    void takeLeaving() {
      while (oldIndex < _entries.length &&
          !keys.contains(_entries[oldIndex].key)) {
        _leave(_entries[oldIndex]);
        next.add(_entries[oldIndex++]);
      }
    }

    for (var i = 0; i < children.length; i++) {
      takeLeaving();
      final key = _keyOf(children[i], i);
      final kept = byKey[key];
      if (kept != null) {
        kept.child = children[i];
        if (kept.leaving) {
          kept.leaving = false;
          kept.controller.forward();
        }
        if (oldIndex < _entries.length && _entries[oldIndex] == kept) {
          oldIndex++;
        }
        next.add(kept);
      } else {
        next.add(
          _entry(children[i], i, shown: false)
            ..fadeOnly = widget.entrance == ColumnEntrance.fade
            ..controller.forward(),
        );
      }
    }
    takeLeaving();
    for (final entry in _entries) {
      if (!next.contains(entry)) {
        _leave(entry);
        next.add(entry);
      }
    }
    _entries = next;
  }

  void _leave(_Entry entry) {
    if (entry.leaving) return;
    entry
      ..leaving = true
      ..fadeOnly = false;
    entry.controller.reverse().whenCompleteOrCancel(() {
      if (!mounted || !entry.leaving || entry.controller.value > 0) return;
      setState(() => _entries.remove(entry));
      entry.dispose();
    });
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: widget.crossAxisAlignment,
    children: [
      for (var i = 0; i < _entries.length; i++)
        KeyedSubtree(
          key: _entries[i].key,
          child: UnfoldTransition(
            sizeFactor: _entries[i].fadeOnly
                ? kAlwaysCompleteAnimation
                : _entries[i].curved,
            // The same shape at every position, so a child that becomes
            // the first one keeps its state.
            child: FadeTransition(
              opacity: _entries[i].curved,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: i == 0 ? 0 : widget.spacing / 2),
                  Offstage(
                    offstage: i == 0,
                    child: widget.separator ?? const SizedBox.shrink(),
                  ),
                  SizedBox(height: i == 0 ? 0 : widget.spacing / 2),
                  _entries[i].child,
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
