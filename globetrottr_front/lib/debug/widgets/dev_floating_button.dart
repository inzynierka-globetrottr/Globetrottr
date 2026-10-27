import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DevFloatingButton extends StatelessWidget {
  final Object heroTag;

  const DevFloatingButton({
    super.key,
    this.heroTag = 'dev_mode_fab',
  });

  @override
  Widget build(BuildContext context) {
    if (!DevConfig.isDevMode) {
      return const SizedBox.shrink();
    }

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.neuShadow,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );

    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: AppColors.accentGold,
      foregroundColor: AppColors.neuShadow,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.neuShadow,
          width: 2,
        ),
      ),
      icon: const Icon(
        Icons.bug_report,
        size: 20,
        color: AppColors.neuShadow,
      ),
      label: Text(
        'DEV MODE',
        style: labelStyle,
      ),
      onPressed: () => context.push('/dev'),
    );
  }
}
