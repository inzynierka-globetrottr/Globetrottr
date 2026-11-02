import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';

/// A small raised pill with a short label, optionally followed by an icon.
class NeuPillButton extends StatelessWidget {
  const NeuPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
  });

  static const _height = 36.0;

  final String label;
  final VoidCallback? onPressed;
  final AppIcons? trailingIcon;

  @override
  Widget build(BuildContext context) => NeuPressable(
    onPressed: onPressed,
    shadows: context.shadows.raised(NeoDepth.sm),
    depth: NeoDepth.xs,
    height: _height,
    borderRadius: BorderRadius.circular(_height / 2),
    padding: EdgeInsets.only(left: 16, right: trailingIcon == null ? 16 : 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(label, style: context.typography.action),
        if (trailingIcon != null) AppIcon(trailingIcon!, size: 16),
      ],
    ),
  );
}
