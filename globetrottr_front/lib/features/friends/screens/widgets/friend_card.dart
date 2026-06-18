import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/extensions/string_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';
import 'package:globetrottr_front/features/friends/data/friendship_response.dart';
import 'package:go_router/go_router.dart';

class FriendCard extends StatelessWidget {
  final FriendshipResponse friend;

  const FriendCard({
    super.key,
    required this.friend,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/friends/${friend.username}/map'),
      child: NeuFloatingContainer(
        width: double.infinity,
        height: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              NeuInsetContainer(
                width: 44,
                height: 44,
                // TODO: replace with profile picture
                child: Text(
                  friend.username.initialOrFallback,
                  style: AppTextStyles.actionButtonText.copyWith(
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                friend.username,
                style: AppTextStyles.rulesetTitle,
              ),
            ],
          ),
        ),
      )
    );
  }
}