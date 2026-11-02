import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/extensions/string_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A user's picture in a sunken circle, or the first letter of the name when
/// there is no picture.
class UserAvatarBubble extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final double size;
  final double? fallbackFontSize;
  final bool isUploading;
  final bool useContainerChrome;

  /// Colour of the fallback letter; the text colour by default.
  final Color? fallbackColor;

  const UserAvatarBubble({
    super.key,
    required this.username,
    this.avatarUrl,
    this.size = 44,
    this.fallbackFontSize,
    this.isUploading = false,
    this.useContainerChrome = true,
    this.fallbackColor,
  });

  /// The letter grows with the circle, as in the mock-up (17 px at 44 px).
  static const _letterScale = 0.39;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final progress = CircularProgressIndicator(
      strokeWidth: 2,
      color: palette.accent,
    );

    final content = ClipOval(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasAvatar)
            Image.network(
              avatarUrl!,
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
      child: content,
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Text(
        username.initialOrFallback,
        style: context.typography.value.copyWith(
          color: fallbackColor,
          fontSize: fallbackFontSize ?? size * _letterScale,
        ),
      ),
    );
  }
}
