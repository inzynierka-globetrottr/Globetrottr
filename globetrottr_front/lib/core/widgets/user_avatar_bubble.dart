import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/extensions/string_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_container.dart';

class UserAvatarBubble extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final double size;
  final double? fallbackFontSize;
  final bool isUploading;
  final bool useContainerChrome;
  final double ringPadding;

  const UserAvatarBubble({
    super.key,
    required this.username,
    this.avatarUrl,
    this.size = 44,
    this.fallbackFontSize,
    this.isUploading = false,
    this.useContainerChrome = true,
    this.ringPadding = 4
  });

  @override
  Widget build(BuildContext context) {
    final double dimension = useContainerChrome
        ? size - (ringPadding * 2)
        : double.infinity;
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    final content = ClipOval(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasAvatar)
            Image.network(
              avatarUrl!,
              width: dimension,
              height: dimension,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentBlue,
                    ),
                  ),
                );
              },
            )
          else
            _buildFallback(),
          if (isUploading)
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!useContainerChrome) return content;

    return NeuContainer(
      elevation: NeuElevation.inset,
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(ringPadding),
        child: content,
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        username.initialOrFallback,
        style: AppTextStyles.actionButtonText.copyWith(
          color: AppColors.accentBlue,
          fontSize: fallbackFontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
