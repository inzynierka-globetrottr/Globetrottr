import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';

class ProfileNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ProfileNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NeuPrimaryButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentBlue, size: 22),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.actionButtonText),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }
}