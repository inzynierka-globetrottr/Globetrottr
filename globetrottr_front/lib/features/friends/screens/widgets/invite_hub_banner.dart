import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';

class InviteHubBanner extends StatelessWidget {
  final int receivedCount;
  final VoidCallback onTap;

  const InviteHubBanner({
    super.key,
    required this.receivedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuPrimaryButton(
      onPressed: onTap,
      width: double.infinity,
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.accentBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Friend requests',
                style: AppTextStyles.rulesetTitle,
              ),
            ),
            if (receivedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$receivedCount',
                  style: AppTextStyles.inputLabel.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accentBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}