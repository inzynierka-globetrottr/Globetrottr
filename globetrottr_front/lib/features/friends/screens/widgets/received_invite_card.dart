import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';
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
    return NeuFloatingContainer(
      width: double.infinity,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            NeuInsetContainer(
              width: 44,
              height: 44,
              child: Text(
                invite.username[0].toUpperCase(),
                style: AppTextStyles.actionButtonText.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                invite.username,
                style: AppTextStyles.rulesetTitle,
              ),
            ),
            Row(
              children: [
                NeuIconButton(
                  onPressed: onAccept,
                  child: const Icon(
                    Icons.check,
                    color: AppColors.accentGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                NeuIconButton(
                  onPressed: onDecline,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.accentRed,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}