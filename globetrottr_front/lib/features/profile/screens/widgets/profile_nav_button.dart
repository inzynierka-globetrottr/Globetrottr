import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';

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
    final palette = context.palette;

    return NeuButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: palette.accent, size: 22),
          const SizedBox(width: 14),
          Text(label),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: palette.textMuted,
            size: 22,
          ),
        ],
      ),
    );
  }
}
