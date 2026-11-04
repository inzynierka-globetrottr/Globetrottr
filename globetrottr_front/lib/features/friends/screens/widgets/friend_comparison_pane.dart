import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/area_split_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/duel_card.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_fog_preview.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_panel.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/place_comparison_card.dart';

/// The user against a friend: both areas on one map, the duel and the
/// places both explore.
class FriendComparisonPane extends ConsumerWidget {
  const FriendComparisonPane({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(friendComparisonProvider(username));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        AreaSplitCard(
          username: username,
          split: comparison.split,
          map: FriendFogPreview(
            username: username,
            mapView: FriendMapView.together,
          ),
        ),
        DuelCard(username: username, comparison: comparison),
        if (comparison.places.isNotEmpty)
          PlaceComparisonCard(places: comparison.places),
      ],
    );
  }
}
