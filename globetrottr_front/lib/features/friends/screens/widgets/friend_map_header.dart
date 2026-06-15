import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';

class FriendMapHeader extends StatelessWidget {
  final String friendUsername;

  const FriendMapHeader({super.key, required this.friendUsername});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50.0,
      left: 16.0,
      right: 16.0,
      child: Row(
        children: [
          NeuIconButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.text,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.neuLight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "Odkrycia gracza: $friendUsername",
                style: AppTextStyles.rulesetTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
