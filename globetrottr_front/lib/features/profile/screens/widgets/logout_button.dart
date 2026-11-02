import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
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
      builder: (context) {
        final palette = context.palette;
        final typography = context.typography;
        return AlertDialog(
          title: Text(l10n.profileUnsyncedTripsTitle, style: typography.title),
          content: Text(
            l10n.profileUnsyncedTripsMessage,
            style: typography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.profileCancel,
                style: typography.action.copyWith(color: palette.accent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.profileLogOutAnyway,
                style: typography.action.copyWith(color: palette.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await notifier.logout(discardUnsyncedPoints: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danger = context.palette.danger;
    return NeuButton(
      onPressed: () => _logout(context, ref),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          Icon(Icons.logout_rounded, color: danger, size: 20),
          Text(
            context.l10n.profileLogOut,
            style: TextStyle(color: danger),
          ),
        ],
      ),
    );
  }
}
