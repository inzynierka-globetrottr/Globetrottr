import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:go_router/go_router.dart';

class FriendCard extends StatelessWidget {
  final FriendshipResponse friend;

  const FriendCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/friends/${friend.username}/map'),
      child: NeuSurface(
        shadows: context.shadows.raised(NeoDepth.lg),
        borderRadius: BorderRadius.circular(24),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            UserAvatarBubble(
              ringPadding: 3,
              username: friend.username,
              avatarUrl: friend.avatarUrl,
            ),
            const SizedBox(width: 14),
            Text(friend.username, style: context.typography.itemTitle),
          ],
        ),
      ),
    );
  }
}
