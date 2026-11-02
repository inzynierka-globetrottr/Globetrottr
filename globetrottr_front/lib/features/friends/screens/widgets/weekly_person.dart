import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/progress_ring.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/provider/weekly_ranking.dart';

/// One person of the "this week" strip: the avatar in a ring filled by the
/// week's area. The user's own circle is sunk in and its ring is gold.
class WeeklyPerson extends StatelessWidget {
  const WeeklyPerson({super.key, required this.entry});

  final WeeklyEntry entry;

  static const width = 74.0;
  static const _circle = 64.0;
  static const _avatar = 50.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final shadows = context.shadows;
    final isMe = entry.isMe;
    final name = isMe ? context.l10n.friendsYou : entry.username;
    final area = formatKm2(
      entry.weeklyKm2,
      Localizations.localeOf(context).toString(),
    );

    return SizedBox(
      width: width,
      child: Column(
        children: [
          NeuSurface.circle(
            shadows: isMe
                ? shadows.inset(NeoDepth.md)
                : shadows.raised(NeoDepth.lg),
            size: _circle,
            child: ProgressRing(
              fill: entry.ringFill,
              color: isMe ? palette.gold : palette.accent,
              radiusRatio: 28 / _circle,
              strokeRatio: 4 / _circle,
              child: Center(
                child: SizedBox.square(
                  dimension: _avatar,
                  child: UserAvatarBubble(
                    username: entry.username,
                    avatarUrl: entry.avatarUrl,
                    size: _avatar,
                    useContainerChrome: false,
                    fallbackColor: isMe ? palette.accent : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.captionStrong.copyWith(
              color: isMe ? palette.accent : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.friendsArea(area),
            style: typography.small,
          ),
        ],
      ),
    );
  }
}
