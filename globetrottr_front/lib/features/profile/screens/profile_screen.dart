import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/logout_button.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_nav_button.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_avatar.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/profile_bio.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/points_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);
    final userProfile = profileState.profile;

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(baseColor: AppColors.background),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                ProfileAvatar(
                  username: userProfile?.username ?? '',
                  avatarUrl: userProfile?.avatarUrl,
                  isUploading: profileState.isUploadingAvatar,
                  onAvatarSelected: profileNotifier.uploadAvatar
                ),

                const SizedBox(height: 16),

                Text(
                  userProfile?.username ?? 'Traveler',
                  style: AppTextStyles.rulesetTitle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                ProfileBio(
                  initialBio: userProfile?.bio ?? '',
                  isUpdatingBio: profileState.isUpdatingBio,
                  onSave: profileNotifier.updateBio
                ),

                const SizedBox(height: 24),

                PointsCard(totalPoints: userProfile?.totalPoints ?? 0),

                const SizedBox(height: 24),

                ProfileNavButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistics',
                  onPressed: () => {}, //context.push('/statistics'),
                ),

                const SizedBox(height: 14),

                ProfileNavButton(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Achievements',
                  onPressed: () => {}, //context.push('/achievements'),
                ),

                const SizedBox(height: 14),

                ProfileNavButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onPressed: () => {}, //context.push('/settings'),
                ),

                const SizedBox(height: 32),

                const LogoutButton(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const NeuBottomNavbar(
          activeItem: NavbarItem.profile,
        ),
      ),
    );
  }
}
