import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/area_split_summary.dart';

/// A map of both discovered areas and how they split into the parts only
/// one of them has seen and the shared part.
class AreaSplitCard extends StatelessWidget {
  const AreaSplitCard({
    super.key,
    required this.username,
    required this.split,
    required this.map,
  });

  final String username;
  final AreaSplit? split;
  final Widget map;

  static const _mapHeight = 196.0;
  static const _mapRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final mapRadius = BorderRadius.circular(_mapRadius);
    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SizedBox(
            height: _mapHeight,
            child: ClipRRect(
              borderRadius: mapRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  map,
                  IgnorePointer(
                    child: NeuInsetShadow(
                      shadows: context.shadows.inset(NeoDepth.md),
                      borderRadius: mapRadius,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AreaSplitSummary(username: username, split: split),
        ],
      ),
    );
  }
}
