import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/neu_tabs.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/area_split_summary.dart';

/// What the friend's full-screen map shows.
enum FriendMapView {
  /// Only the friend's discovered area.
  theirs,

  /// The friend's and the user's area together.
  together;

  /// The view named in a route's query, the friend's area by default.
  static FriendMapView fromQuery(String? name) =>
      values.asNameMap()[name] ?? theirs;
}

/// The card at the bottom of the friend's map: the choice of the view and,
/// for both areas together, how they split.
class FriendMapPanel extends ConsumerWidget {
  const FriendMapPanel({
    super.key,
    required this.username,
    required this.view,
    required this.onView,
  });

  final String username;
  final FriendMapView view;
  final ValueChanged<FriendMapView> onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NeuSurface(
      shadows: context.shadows.mapControl,
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          NeuTabs<FriendMapView>(
            stretch: true,
            selected: view,
            onSelected: onView,
            tabs: [
              NeuTab(
                value: FriendMapView.theirs,
                label: l10n.friendMapTheirs(username),
              ),
              NeuTab(
                value: FriendMapView.together,
                label: l10n.friendMapTogether,
              ),
            ],
          ),
          if (view == FriendMapView.together)
            AreaSplitSummary(
              username: username,
              split: ref.watch(friendComparisonProvider(username)).split,
            ),
        ],
      ),
    );
  }
}
