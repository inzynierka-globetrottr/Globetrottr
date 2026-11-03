import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// The points of a quest as steps joined by lines: visited points are filled,
/// the next one is ringed and the rest are sunk in. A line is filled once
/// both of its points are visited.
class QuestSteps extends StatelessWidget {
  const QuestSteps({super.key, required this.visited, this.next})
    : _count = null;

  /// Muted steps of an empty card.
  const QuestSteps.placeholder({super.key})
    : visited = const [],
      next = null,
      _count = _placeholderCount;

  static const _placeholderCount = 5;

  final List<bool> visited;
  final int? next;
  final int? _count;

  static const _dot = 20.0;
  static const _ring = 3.0;
  static const _line = 4.0;

  bool _isVisited(int i) => i < visited.length && visited[i];

  @override
  Widget build(BuildContext context) {
    final count = _count ?? visited.length;
    return Row(
      spacing: 8,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0)
            Expanded(
              child: _StepLine(filled: _isVisited(i - 1) && _isVisited(i)),
            ),
          _StepDot(
            state: _isVisited(i)
                ? _StepState.visited
                : (i == next ? _StepState.next : _StepState.ahead),
          ),
        ],
      ],
    );
  }
}

enum _StepState { visited, next, ahead }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    return switch (state) {
      _StepState.visited => NeuSurface.circle(
        size: QuestSteps._dot,
        color: palette.accent,
        shadows: shadows.shade(NeoDepth.xs),
      ),
      _StepState.next => NeuSurface.circle(
        size: QuestSteps._dot,
        shadows: shadows.inset(NeoDepth.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.danger, width: QuestSteps._ring),
          ),
        ),
      ),
      _StepState.ahead => NeuSurface.circle(
        size: QuestSteps._dot,
        shadows: shadows.inset(NeoDepth.xs),
      ),
    };
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) => NeuSurface(
    height: QuestSteps._line,
    borderRadius: BorderRadius.circular(QuestSteps._line / 2),
    color: filled ? context.palette.accent : null,
    shadows: filled ? const [] : context.shadows.inset(NeoDepth.xs),
  );
}
