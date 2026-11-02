import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';

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
    final palette = context.palette;

    return NeuButton(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.mail_outline_rounded, color: palette.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(context.l10n.friendsRequestsBanner)),
          if (receivedCount > 0)
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  '$receivedCount',
                  style: context.typography.captionStrong.copyWith(
                    color: palette.onAccent,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: palette.accent, size: 20),
        ],
      ),
    );
  }
}
