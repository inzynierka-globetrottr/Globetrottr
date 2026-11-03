import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:go_router/go_router.dart';

class FriendMapHeader extends StatelessWidget {
  final String friendUsername;

  const FriendMapHeader({super.key, required this.friendUsername});

  @override
  Widget build(BuildContext context) {
    final topSafeInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topSafeInset + 16.0,
      left: 16.0,
      right: 16.0,
      child: Row(
        children: [
          NeuIconButton(
            onPressed: () => context.pop(),
            child: const Icon(Icons.arrow_back, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: NeuSurface(
              shadows: context.shadows.mapControl,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                context.l10n.friendsPlayerFog(friendUsername),
                style: context.typography.itemTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
