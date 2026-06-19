import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/extensions/string_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_container.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
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
    return NeuContainer(
      elevation: NeuElevation.inset,
      width: double.infinity,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            NeuContainer(
              elevation: NeuElevation.inset,
              width: 44,
              height: 44,
              child: Text(
                invite.username.initialOrFallback,
                style: AppTextStyles.actionButtonText.copyWith(
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(invite.username, style: AppTextStyles.rulesetTitle),
            ),
            NeuIconButton(
              onPressed: onCancel,
              child: const Icon(
                Icons.close,
                color: AppColors.accentRed,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
