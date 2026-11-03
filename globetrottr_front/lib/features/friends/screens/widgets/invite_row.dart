import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_list_row.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';

/// A received invite with buttons to reject or accept it.
class InviteRow extends ConsumerWidget {
  const InviteRow({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final FriendshipResponse invite;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  static const _button = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final username = invite.username;
    return NeuListRow(
      leading: UserAvatarBubble(
        username: username,
        avatarUrl: invite.avatarUrl,
      ),
      title: username,
      subtitle: ref.watch(inviteContextProvider(username)),
      trailing: [
        NeuIconButton(
          size: _button,
          depth: NeoDepth.md,
          fill: NeuFill.danger,
          semanticLabel: l10n.friendsReject(username),
          onPressed: onReject,
          child: const AppIcon(AppIcons.close, size: 18),
        ),
        NeuIconButton(
          size: _button,
          depth: NeoDepth.md,
          fill: NeuFill.accent,
          semanticLabel: l10n.friendsAccept(username),
          onPressed: onAccept,
          child: const AppIcon(AppIcons.check, size: 18),
        ),
      ],
    );
  }
}
