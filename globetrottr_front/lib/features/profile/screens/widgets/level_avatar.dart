import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/level_badge.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';

/// The large avatar of a profile: the picture in a sunk circle, a ring
/// filled by the progress to the next level and the level on its corner.
class LevelAvatar extends StatelessWidget {
  const LevelAvatar({
    super.key,
    required this.username,
    required this.level,
    required this.fill,
    this.avatarUrl,
    this.isUploading = false,
  });

  final String username;
  final String? avatarUrl;
  final bool isUploading;

  /// Null while unknown.
  final int? level;

  /// Progress to the next level, 0 to 1.
  final double fill;

  static const size = 116.0;
  static const _picture = 84.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    return LevelBadge(
      level: level,
      size: LevelBadgeSize.large,
      child: NeuSurface.circle(
        size: size,
        shadows: shadows.raised(NeoDepth.xl),
        child: ProgressRing(
          fill: fill,
          color: palette.accent,
          trackColor: palette.divider,
          radiusRatio: 51 / size,
          strokeRatio: 6 / size,
          child: Center(
            child: NeuSurface.circle(
              size: _picture,
              shadows: shadows.inset(NeoDepth.md),
              child: UserAvatarBubble(
                username: username,
                avatarUrl: avatarUrl,
                isUploading: isUploading,
                size: _picture,
                useContainerChrome: false,
                fallbackColor: palette.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
