import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:go_router/go_router.dart';

enum NavbarItem { friends, map, profile, quests }

class NeuBottomNavbar extends ConsumerWidget {
  final NavbarItem activeItem;

  const NeuBottomNavbar({super.key, required this.activeItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: NeuFloatingContainer(
        width: double.infinity,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavbarButton(
                icon: Icons.map_rounded,
                isActive: activeItem == NavbarItem.map,
                onTap: () => context.go('/map'),
              ),
              _NavbarButton(
                icon: Icons.emoji_events_rounded,
                isActive: activeItem == NavbarItem.quests,
                onTap: () => {}, //context.go('/quests'),
              ),
              _NavbarButton(
                icon: Icons.people_rounded,
                isActive: activeItem == NavbarItem.friends,
                onTap: () => context.go('/friends'),
              ),
              _NavbarButton(
                icon: Icons.person_rounded,
                isActive: activeItem == NavbarItem.profile,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavbarButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: Neumorphic(
        style: NeumorphicStyle(
          boxShape: NeumorphicBoxShape.roundRect(
            const BorderRadius.all(Radius.circular(16)),
          ),
          depth: isActive ? -4 : 0,
          intensity: 1,
          shadowLightColor: AppColors.neuLight,
          shadowDarkColor: AppColors.neuShadow,
          shadowLightColorEmboss: AppColors.neuLight,
          shadowDarkColorEmboss: AppColors.neuShadow,
          color: AppColors.background,
        ),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: isActive
                  ? const Color(0xFF4FD1C5)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
