import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_list_row.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';
import 'package:globetrottr_front/core/widgets/level_badge.dart';

/// A friend with their level, discovered area and a button that opens them.
class FriendRow extends ConsumerWidget {
  const FriendRow({super.key, required this.friend, required this.onOpen});

  final FriendshipResponse friend;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activity = ref.watch(friendActivityProvider(friend.username));
    final area = formatKm2(
      activity.totalKm2,
      Localizations.localeOf(context).toString(),
      decimals: 1,
    );
    return NeuListRow(
      leading: LevelBadge(
        level: activity.level,
        child: UserAvatarBubble(
          username: friend.username,
          avatarUrl: friend.avatarUrl,
        ),
      ),
      title: friend.username,
      subtitle: l10n.friendsArea(area),
      trailing: [
        NeuIconButton(
          size: 40,
          depth: NeoDepth.md,
          fill: NeuFill.accent,
          semanticLabel: l10n.friendsOpen(friend.username),
          onPressed: onOpen,
          child: const AppIcon(AppIcons.chevronRight, size: 18),
        ),
      ],
    );
  }
}
