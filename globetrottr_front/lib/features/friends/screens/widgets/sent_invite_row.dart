import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/widgets/neu_list_row.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

/// An invite the user sent, waiting for an answer, with a button to take it
/// back.
class SentInviteRow extends StatelessWidget {
  const SentInviteRow({super.key, required this.invite, required this.onUndo});

  final FriendshipResponse invite;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NeuListRow(
      leading: UserAvatarBubble(
        username: invite.username,
        avatarUrl: invite.avatarUrl,
      ),
      title: invite.username,
      // TODO(data): "Pending for 2 days" once the backend returns when the
      // invite was sent.
      subtitle: l10n.friendsPending,
      trailing: [
        NeuPillButton(
          label: l10n.friendsUndo,
          size: NeuPillSize.medium,
          onPressed: onUndo,
        ),
      ],
    );
  }
}
