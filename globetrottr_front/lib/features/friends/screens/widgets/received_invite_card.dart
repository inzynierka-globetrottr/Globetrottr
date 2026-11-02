import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class ReceivedInviteCard extends StatelessWidget {
  final FriendshipResponse invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ReceivedInviteCard({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.lg),
      borderRadius: BorderRadius.circular(24),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          UserAvatarBubble(
            ringPadding: 3,
            username: invite.username,
            avatarUrl: invite.avatarUrl,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(invite.username, style: context.typography.itemTitle),
          ),
          NeuIconButton(
            onPressed: onAccept,
            child: Icon(Icons.check, color: palette.accent),
          ),
          const SizedBox(width: 8),
          NeuIconButton(
            onPressed: onDecline,
            child: Icon(Icons.close, color: palette.danger),
          ),
        ],
      ),
    );
  }
}
