import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_fog_preview.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/discovered_area_card.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/level_details_card.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_hero.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_stats_section.dart';

/// A friend's profile: the same layout as the own one, with their fog on
/// the card of the discovered area.
class FriendProfilePane extends ConsumerWidget {
  const FriendProfilePane({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(friendProfileStatsProvider(username));
    final avatarUrl = ref.watch(
      friendsProvider.select(
        (state) => state.friends
            .where((friend) => friend.username == username)
            .firstOrNull
            ?.avatarUrl,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        ProfileHero(
          username: username,
          avatarUrl: avatarUrl,
          level: stats.level,
          details: LevelDetailsCard(stats: stats, isFriend: true),
        ),
        DiscoveredAreaCard(
          totalKm2: stats.totalKm2,
          map: FriendFogPreview(username: username),
        ),
        ProfileStatsSection(stats: stats),
      ],
    );
  }
}
