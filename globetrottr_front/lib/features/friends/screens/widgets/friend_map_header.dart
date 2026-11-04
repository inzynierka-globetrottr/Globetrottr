import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';

/// The top of the friend's map: back, and the friend with their discovered
/// area in a pill.
class FriendMapHeader extends ConsumerWidget {
  const FriendMapHeader({super.key, required this.friendUsername});

  final String friendUsername;

  static const _height = 50.0;
  static const _avatar = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();
    final totalKm2 = ref.watch(
      friendProfileStatsProvider(friendUsername).select((s) => s.totalKm2),
    );
    final avatarUrl = ref.watch(friendAvatarUrlProvider(friendUsername));
    return Row(
      spacing: 12,
      children: [
        const NeuBackButton(overMap: true),
        Expanded(
          child: NeuSurface(
            shadows: context.shadows.mapControl,
            borderRadius: BorderRadius.circular(_height / 2),
            height: _height,
            padding: const EdgeInsets.only(left: 5, right: 16),
            child: Row(
              spacing: 10,
              children: [
                UserAvatarBubble(
                  username: friendUsername,
                  avatarUrl: avatarUrl,
                  size: _avatar,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendUsername,
                        style: typography.value.copyWith(height: 1.15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.l10n.friendMapArea(
                          formatKm2(totalKm2, locale, decimals: 1),
                        ),
                        style: typography.caption.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
