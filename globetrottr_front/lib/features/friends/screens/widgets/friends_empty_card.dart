import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// Shown instead of the weekly strip and the list while there are no friends.
class FriendsEmptyCard extends StatelessWidget {
  const FriendsEmptyCard({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        spacing: 12,
        children: [
          AppIcon(
            AppIcons.navFriends,
            size: 40,
            color: context.palette.textMuted,
          ),
          Text(
            l10n.friendsEmptyTitle,
            style: typography.itemTitle,
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.friendsEmptyBody,
            style: typography.note,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          NeuPillButton(
            label: l10n.friendsAdd,
            size: NeuPillSize.medium,
            trailingIcon: AppIcons.plus,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
