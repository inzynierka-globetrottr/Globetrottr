import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';

class ProfileAvatar extends ConsumerWidget {
  final String? avatarUrl;
  final String username;
  final bool isUploading;
  final VoidCallback? onAvatarTap;

  const ProfileAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.isUploading = false,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Neumorphic(
                  padding: const EdgeInsets.all(6),
                  style: const NeumorphicStyle(
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: -4,
                    intensity: 1,
                    shadowLightColorEmboss: AppColors.neuLight,
                    shadowDarkColorEmboss: AppColors.neuShadow,
                    color: AppColors.background,
                  ),
                  child: UserAvatarBubble(
                    username: username,
                    avatarUrl: avatarUrl,
                    isUploading: isUploading,
                    fallbackFontSize: 32,
                    useContainerChrome: false,
                  ),
                ),
              ),

              Positioned(
                bottom: -2,
                right: -2,
                child: Neumorphic(
                  style: const NeumorphicStyle(
                    boxShape: NeumorphicBoxShape.circle(),
                    depth: 3,
                    intensity: 0.9,
                    shadowLightColor: AppColors.neuLight,
                    shadowDarkColor: AppColors.neuShadow,
                    color: AppColors.background,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
