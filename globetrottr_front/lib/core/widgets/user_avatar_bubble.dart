import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/extensions/string_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

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
    this.ringPadding = 4,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final double dimension = useContainerChrome
        ? size - (ringPadding * 2)
        : double.infinity;
    final bool hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final progress = CircularProgressIndicator(
      strokeWidth: 2,
      color: palette.accent,
    );

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
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallback(context),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: progress);
              },
            )
          else
            _buildFallback(context),
          if (isUploading)
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Center(child: progress),
            ),
        ],
      ),
    );

    if (!useContainerChrome) return content;

    return NeuSurface.circle(
      shadows: context.shadows.inset(NeoDepth.sm),
      size: size,
      padding: EdgeInsets.all(ringPadding),
      child: content,
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Text(
        username.initialOrFallback,
        style: context.typography.value.copyWith(
          color: context.palette.accent,
          fontSize: fallbackFontSize,
        ),
      ),
    );
  }
}
