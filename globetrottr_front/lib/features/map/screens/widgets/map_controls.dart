import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// The column of map buttons in the top right corner: layers and centring
/// on the player.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.onLayers,
    required this.onRecenter,
  });

  final VoidCallback onLayers;
  final VoidCallback onRecenter;

  static const width = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NeuSurface(
      shadows: context.shadows.mapControl,
      borderRadius: BorderRadius.circular(width / 2),
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            icon: AppIcons.layers,
            label: l10n.mapLayers,
            onTap: onLayers,
          ),
          const NeuDivider(length: 30),
          _ControlButton(
            icon: AppIcons.recenter,
            label: l10n.mapRecenter,
            color: context.palette.accent,
            onTap: onRecenter,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: MapControls.width,
        height: 57,
        child: Center(child: AppIcon(icon, color: color)),
      ),
    ),
  );
}
