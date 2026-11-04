import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A labelled tile under the avatar that opens a screen of the profile.
class ProfileShortcutTile extends StatelessWidget {
  const ProfileShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => NeuPressable(
    onPressed: onPressed,
    shadows: context.shadows.raised(NeoDepth.lg),
    pressedShadows: context.shadows.inset(NeoDepth.xs),
    borderRadius: BorderRadius.circular(20),
    padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
    semanticLabel: label,
    child: ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          NeuSurface.circle(
            size: 44,
            shadows: context.shadows.inset(NeoDepth.sm),
            child: Center(
              child: AppIcon(icon, color: context.palette.accent),
            ),
          ),
          Text(label, style: context.typography.action),
        ],
      ),
    ),
  );
}
