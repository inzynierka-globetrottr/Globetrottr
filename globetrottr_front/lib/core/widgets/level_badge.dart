import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

enum LevelBadgeSize {
  /// On an avatar in a list.
  small(height: 20, border: 2, right: -4, bottom: -3),

  /// On the large avatar of a profile.
  large(height: 34, border: 3, right: 2, bottom: -4);

  const LevelBadgeSize({
    required this.height,
    required this.border,
    required this.right,
    required this.bottom,
  });

  final double height;
  final double border;
  final double right;
  final double bottom;
}

/// The level in an accent pill on the corner of an avatar.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    required this.child,
    this.size = LevelBadgeSize.small,
  });

  /// Null while the level is unknown.
  final int? level;
  final Widget child;
  final LevelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final small = size == LevelBadgeSize.small;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: size.right,
          bottom: size.bottom,
          child: Container(
            height: size.height,
            constraints: BoxConstraints(minWidth: size.height),
            padding: EdgeInsets.symmetric(
              horizontal: (small ? 5 : 8) - size.border,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(size.height / 2),
              border: Border.all(color: palette.background, width: size.border),
            ),
            child: Text(
              level?.toString() ?? context.l10n.friendsLevelUnknown,
              style: (small ? typography.smallStrong : typography.action)
                  .copyWith(color: palette.onAccent, height: 1),
            ),
          ),
        ),
      ],
    );
  }
}
