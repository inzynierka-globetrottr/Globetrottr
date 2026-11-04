import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:globetrottr_front/features/profile/provider/profile_state.dart';
import 'package:globetrottr_front/features/profile/provider/profile_stats.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/avatar_picker.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/discovered_area_card.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/level_details_card.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_hero.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_shortcut_tile.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_stats_section.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/settings_dialog.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _side = 20.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
      ref.read(questsProvider.notifier).loadQuestsOnce();
    });
  }

  void _openSettings() => showDialog<void>(
    context: context,
    builder: (_) =>
        SettingsDialog(onChangePhoto: () => pickAndUploadAvatar(context, ref)),
  );

  void _onProfileChanged(ProfileState? previous, ProfileState next) {
    final uploadEnded =
        (previous?.isUploadingAvatar ?? false) && !next.isUploadingAvatar;
    if (!uploadEnded || next.errorMessage == null) return;
    // TODO: show error differently than with a snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.localizeErrorMessage(next.errorMessage)),
        backgroundColor: context.palette.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(profileProvider, _onProfileChanged);
    final profile = ref.watch(profileProvider.select((s) => s.profile));
    final isUploading = ref.watch(
      profileProvider.select((s) => s.isUploadingAvatar),
    );
    final stats = ref.watch(myProfileStatsProvider);

    return Scaffold(
      // The profile scrolls on under the floating navigation.
      extendBody: true,
      bottomNavigationBar: const NeuBottomNavbar(
        activeItem: NavbarItem.profile,
      ),
      // Read inside the scaffold, whose padding includes the navigation.
      body: Builder(
        builder: (context) {
          final safe = MediaQuery.paddingOf(context);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _side,
              safe.top + 24,
              _side,
              safe.bottom + 20,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    ProfileHero(
                      username:
                          profile?.username ?? l10n.profileDefaultUsername,
                      avatarUrl: profile?.avatarUrl,
                      isUploading: isUploading,
                      level: stats.level,
                      details: LevelDetailsCard(stats: stats),
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: ProfileShortcutTile(
                            icon: AppIcons.route,
                            label: l10n.profileRoutes,
                            // TODO(data): open the routes screen once it
                            // exists.
                            onPressed: () {},
                          ),
                        ),
                        Expanded(
                          child: ProfileShortcutTile(
                            icon: AppIcons.stats,
                            label: l10n.profileStatistics,
                            // TODO(data): open the statistics screen once it
                            // exists.
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    DiscoveredAreaCard(totalKm2: stats.totalKm2),
                    ProfileStatsSection(stats: stats),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: NeuIconButton(
                    size: 48,
                    depth: NeoDepth.lg,
                    semanticLabel: l10n.profileSettings,
                    onPressed: _openSettings,
                    child: const AppIcon(AppIcons.settings),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
