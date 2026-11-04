import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/neu_tabs.dart';

/// What a friend's screen shows.
enum FriendView { profile, comparison }

/// The back button, the friend's name and the tabs between their profile
/// and the comparison.
class FriendProfileHeader extends StatelessWidget {
  const FriendProfileHeader({
    super.key,
    required this.username,
    required this.view,
    required this.onView,
  });

  final String username;
  final FriendView view;
  final ValueChanged<FriendView> onView;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      spacing: 12,
      children: [
        const NeuBackButton(),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              username,
              style: context.typography.title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        NeuTabs<FriendView>(
          selected: view,
          onSelected: onView,
          tabs: [
            NeuTab(
              value: FriendView.profile,
              icon: AppIcons.navProfile,
              label: l10n.friendTabProfile,
            ),
            NeuTab(
              value: FriendView.comparison,
              icon: AppIcons.compare,
              label: l10n.friendTabComparison,
            ),
          ],
        ),
      ],
    );
  }
}
