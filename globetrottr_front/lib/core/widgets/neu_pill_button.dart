import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

enum NeuPillSize {
  /// A corner action of a screen, e.g. "Skip".
  small(36, NeoDepth.sm),

  /// An action inside a list row, e.g. "Undo".
  medium(40, NeoDepth.md);

  const NeuPillSize(this.height, this.depth);

  final double height;
  final NeoDepth depth;
}

/// A raised pill with a short label, optionally followed by an icon.
class NeuPillButton extends StatelessWidget {
  const NeuPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.size = NeuPillSize.small,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIcons? trailingIcon;
  final NeuPillSize size;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final small = size == NeuPillSize.small;
    return NeuPressable(
      onPressed: onPressed,
      shadows: context.shadows.raised(size.depth),
      pressedShadows: context.shadows.inset(NeoDepth.xs),
      height: size.height,
      borderRadius: BorderRadius.circular(size.height / 2),
      padding: EdgeInsets.only(
        left: small ? 16 : 14,
        right: trailingIcon == null ? (small ? 16 : 14) : 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(label, style: small ? typography.action : typography.label),
          if (trailingIcon != null) AppIcon(trailingIcon!, size: 16),
        ],
      ),
    );
  }
}
