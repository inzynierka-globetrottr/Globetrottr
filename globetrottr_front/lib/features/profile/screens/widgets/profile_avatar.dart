import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/user_avatar_bubble.dart';

class ProfileAvatar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final shadows = context.shadows;

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
                child: NeuSurface.circle(
                  shadows: shadows.inset(NeoDepth.md),
                  padding: const EdgeInsets.all(6),
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
                child: NeuSurface.circle(
                  shadows: shadows.raised(NeoDepth.sm),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 18,
                    color: context.palette.text,
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
