import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';

class GoogleLoginSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGooglePressed;

  const GoogleLoginSection({
    super.key,
    required this.isLoading,
    required this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return NeuPrimaryButton(
      onPressed: isLoading ? null : onGooglePressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.accentRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('G', style: AppTextStyles.rulesetTitle),
          ),
          const SizedBox(width: 14),
          Text(
            context.l10n.authGoogleAccount,
            style: AppTextStyles.actionButtonText,
          ),
        ],
      ),
    );
  }
}
