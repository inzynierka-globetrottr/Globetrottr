import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final notifier = ref.read(authProvider.notifier);
    if (await notifier.logout()) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          l10n.profileUnsyncedTripsTitle,
          style: const TextStyle(color: AppColors.text),
        ),
        content: Text(
          l10n.profileUnsyncedTripsMessage,
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.profileCancel,
              style: const TextStyle(color: AppColors.accentBlue),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.profileLogOutAnyway,
              style: const TextStyle(color: AppColors.accentRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await notifier.logout(discardUnsyncedPoints: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NeuPrimaryButton(
      onPressed: () => _logout(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.accentRed,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.profileLogOut,
              style: AppTextStyles.actionButtonText.copyWith(
                color: AppColors.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
