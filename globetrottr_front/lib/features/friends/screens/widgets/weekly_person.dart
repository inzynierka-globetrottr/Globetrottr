import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/area_format.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
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
            child: CustomPaint(
              painter: _RingPainter(
                fill: entry.ringFill,
                color: isMe ? palette.gold : palette.accent,
              ),
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  static const _stroke = 4.0;

  /// Distance of the ring from the centre in a 64 px circle.
  static const _radiusRatio = 28 / 64;

  @override
  void paint(Canvas canvas, Size size) {
    if (fill <= 0) return;
    final radius = size.width * _radiusRatio;
    canvas.drawArc(
      Rect.fromCircle(center: size.center(Offset.zero), radius: radius),
      -math.pi / 2,
      2 * math.pi * fill.clamp(0, 1),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill || old.color != color;
}
