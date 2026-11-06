import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// The tabs in the order of the navigation, which is also the order of the
/// tab branches of the router.
enum NavbarItem {
  map('/map', AppIcons.navMap),
  quests('/quests', AppIcons.navQuests),
  friends('/friends', AppIcons.navFriends),
  profile('/profile', AppIcons.navProfile);

  const NavbarItem(this.route, this.icon);

  final String route;
  final AppIcons icon;

  String label(AppLocalizations l10n) => switch (this) {
    NavbarItem.map => l10n.navMap,
    NavbarItem.quests => l10n.navQuests,
    NavbarItem.friends => l10n.navFriends,
    NavbarItem.profile => l10n.navProfile,
  };
}

/// The floating bottom navigation. The accent pill and the label colours
/// are on the active tab at once; over the map the bar casts a darker
/// shadow.
class NeuBottomNavbar extends StatelessWidget {
  const NeuBottomNavbar({
    super.key,
    required this.activeItem,
    this.overMap = false,
    this.onSelect,
  });

  final NavbarItem activeItem;
  final bool overMap;

  /// Opens a tab; by default goes to its route.
  final ValueChanged<NavbarItem>? onSelect;

  /// Space between the bar and the system navigation (gesture bar or
  /// buttons), so the bar does not touch it.
  static const gapAboveSystemBar = 12.0;

  /// Space under the bar on a screen without system navigation.
  static const minBottomMargin = 16.0;

  static const _sideMargin = 12.0;
  static const _height = 76.0;
  static const _spacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;
    final motion = context.motion;
    final systemBar = MediaQuery.paddingOf(context).bottom;
    final select = onSelect ?? (item) => context.go(item.route);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _sideMargin,
        0,
        _sideMargin,
        math.max(minBottomMargin, systemBar + gapAboveSystemBar),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: overMap ? 1 : 0),
        duration: motion.short,
        curve: motion.curve,
        builder: (context, mapShade, child) => NeuSurface(
          shadows: lerpShadows(
            shadows.raised(NeoDepth.xl),
            shadows.mapNav,
            mapShade,
          ),
          borderRadius: BorderRadius.circular(28),
          height: _height,
          padding: const EdgeInsets.all(8),
          child: child,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = NavbarItem.values.length;
            final tabWidth =
                (constraints.maxWidth - _spacing * (count - 1)) / count;
            return Stack(
              children: [
                Positioned(
                  left: activeItem.index * (tabWidth + _spacing),
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: const _Pill(),
                ),
                Row(
                  spacing: _spacing,
                  children: [
                    for (final item in NavbarItem.values)
                      Expanded(
                        child: _NavbarTab(
                          item: item,
                          isActive: item == activeItem,
                          onTap: () => select(item),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) => NeuSurface(
    shadows: context.shadows.raisedAccent(NeoDepth.md),
    borderRadius: BorderRadius.circular(20),
    color: context.palette.accent,
  );
}

class _NavbarTab extends StatelessWidget {
  const _NavbarTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavbarItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final color = isActive ? palette.onAccent : palette.textMuted;
    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            AppIcon(item.icon, color: color),
            Text(
              item.label(context.l10n),
              style: (isActive ? typography.captionStrong : typography.caption)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
