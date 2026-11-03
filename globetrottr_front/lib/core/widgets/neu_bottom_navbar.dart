import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

/// The floating bottom navigation. Over the map it casts a darker shadow.
class NeuBottomNavbar extends StatelessWidget {
  const NeuBottomNavbar({
    super.key,
    required this.activeItem,
    this.overMap = false,
  });

  final NavbarItem activeItem;
  final bool overMap;

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: NeuSurface(
        shadows: overMap ? shadows.mapNav : shadows.raised(NeoDepth.xl),
        borderRadius: BorderRadius.circular(28),
        height: 76,
        padding: const EdgeInsets.all(8),
        child: Row(
          spacing: 6,
          children: [
            for (final item in NavbarItem.values)
              Expanded(
                child: _NavbarTab(
                  item: item,
                  isActive: item == activeItem,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavbarTab extends StatelessWidget {
  const _NavbarTab({required this.item, required this.isActive});

  final NavbarItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final color = isActive ? palette.onAccent : palette.textMuted;
    final content = Column(
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
    );

    return Semantics(
      button: true,
      selected: isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? null : () => context.go(item.route),
        child: isActive
            ? NeuSurface(
                shadows: context.shadows.raisedAccent(NeoDepth.md),
                borderRadius: BorderRadius.circular(20),
                color: palette.accent,
                child: content,
              )
            : content,
      ),
    );
  }
}
