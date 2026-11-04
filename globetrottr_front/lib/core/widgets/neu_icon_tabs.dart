import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// One tab of [NeuIconTabs]; its label is read out instead of the icon.
typedef NeuIconTab<T> = ({T value, AppIcons icon, String label});

/// Icon-only tabs in a sunk pill; the selected one is raised and tinted
/// with the accent.
class NeuIconTabs<T> extends StatelessWidget {
  const NeuIconTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<NeuIconTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  static const _inner = 4.0;
  static const _tabWidth = 44.0;
  static const _tabHeight = 42.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    return NeuSurface(
      shadows: shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(_tabHeight / 2 + _inner),
      padding: const EdgeInsets.all(_inner),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _inner,
        children: [
          for (final tab in tabs)
            Semantics(
              button: true,
              selected: tab.value == selected,
              label: tab.label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(tab.value),
                child: NeuSurface(
                  width: _tabWidth,
                  height: _tabHeight,
                  borderRadius: BorderRadius.circular(_tabHeight / 2),
                  color: tab.value == selected ? null : Colors.transparent,
                  shadows: tab.value == selected
                      ? shadows.raised(NeoDepth.md)
                      : const [],
                  child: Center(
                    child: AppIcon(
                      tab.icon,
                      color: tab.value == selected
                          ? palette.accent
                          : palette.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
