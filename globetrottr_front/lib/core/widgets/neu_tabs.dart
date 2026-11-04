import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// One tab of [NeuTabs]: an icon, with the label read out instead, or the
/// label itself when there is no icon.
@immutable
class NeuTab<T> {
  const NeuTab({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final AppIcons? icon;
}

/// Tabs in a sunk pill; the selected one is raised and tinted with the
/// accent. Icon tabs keep their size; with [stretch] the tabs share the
/// whole width.
class NeuTabs<T> extends StatelessWidget {
  const NeuTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.stretch = false,
  });

  final List<NeuTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool stretch;

  static const _inner = 4.0;
  static const _iconWidth = 44.0;
  static const _height = 42.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    final typography = context.typography;

    Widget tab(NeuTab<T> tab) {
      final isSelected = tab.value == selected;
      final color = isSelected ? palette.accent : palette.textMuted;
      final icon = tab.icon;
      return Semantics(
        button: true,
        selected: isSelected,
        label: tab.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelected(tab.value),
          child: NeuSurface(
            width: icon == null ? null : _iconWidth,
            height: _height,
            borderRadius: BorderRadius.circular(_height / 2),
            // The unselected tab must not cover the sunk pill's shadow.
            color: isSelected ? null : Colors.transparent,
            shadows: isSelected ? shadows.raised(NeoDepth.md) : const [],
            padding: icon == null
                ? const EdgeInsets.symmetric(horizontal: 12)
                : null,
            child: Center(
              child: icon != null
                  ? AppIcon(icon, color: color)
                  : Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.action.copyWith(
                        color: color,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return NeuSurface(
      shadows: shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(_height / 2 + _inner),
      padding: const EdgeInsets.all(_inner),
      child: Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        spacing: _inner,
        children: [
          for (final item in tabs)
            if (stretch) Expanded(child: tab(item)) else tab(item),
        ],
      ),
    );
  }
}
