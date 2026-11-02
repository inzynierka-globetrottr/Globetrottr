import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// The level in a small accent pill on the corner of an avatar.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, required this.child});

  /// Null while the level is unknown.
  final int? level;
  final Widget child;

  static const _height = 20.0;
  static const _border = 2.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          bottom: -3,
          child: Container(
            height: _height,
            constraints: const BoxConstraints(minWidth: _height),
            padding: const EdgeInsets.symmetric(horizontal: 5 - _border),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(_height / 2),
              border: Border.all(color: palette.background, width: _border),
            ),
            child: Text(
              level?.toString() ?? context.l10n.friendsLevelUnknown,
              style: context.typography.smallStrong.copyWith(
                color: palette.onAccent,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
