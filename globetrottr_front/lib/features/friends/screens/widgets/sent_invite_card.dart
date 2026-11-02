import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';

class SentInviteCard extends StatelessWidget {
  final FriendshipResponse invite;
  final VoidCallback onCancel;

  const SentInviteCard({
    super.key,
    required this.invite,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      shadows: context.shadows.inset(NeoDepth.md),
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
            onPressed: onCancel,
            child: Icon(Icons.close, color: context.palette.danger),
          ),
        ],
      ),
    );
  }
}
