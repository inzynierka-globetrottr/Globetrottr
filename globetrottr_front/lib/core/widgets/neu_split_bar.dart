import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// One coloured part of a [NeuSplitBar].
typedef NeuSplitPart = ({double share, Color color});

/// A sunk track divided into coloured parts side by side, e.g. the user's
/// value against a friend's. An empty list leaves the track empty.
class NeuSplitBar extends StatelessWidget {
  const NeuSplitBar({super.key, required this.parts, this.semanticLabel});

  /// Shares of the whole width, left to right; parts of zero are left out.
  final List<NeuSplitPart> parts;
  final String? semanticLabel;

  static const _height = 14.0;
  static const _inner = 3.0;
  static const _gap = 3.0;
  static const _end = Radius.circular(5);
  static const _join = Radius.circular(2);

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final part in parts)
        if (part.share > 0) part,
    ];
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: NeuSurface(
        height: _height,
        borderRadius: BorderRadius.circular(_height / 2),
        shadows: context.shadows.inset(NeoDepth.sm),
        padding: const EdgeInsets.all(_inner),
        child: Row(
          spacing: _gap,
          children: [
            for (var i = 0; i < visible.length; i++)
              Expanded(
                flex: (visible[i].share * 1000).round().clamp(1, 1000),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: visible[i].color,
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0 ? _end : _join,
                      right: i == visible.length - 1 ? _end : _join,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
