import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_illustrations.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_illustration.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

/// One map view in the layers sheet: a picture, its name and a radio. The
/// chosen one is sunk in.
class MapViewOption extends StatelessWidget {
  const MapViewOption({
    super.key,
    required this.view,
    required this.selected,
    required this.onTap,
  });

  final MapView view;
  final bool selected;
  final VoidCallback onTap;

  static const _picture = 56.0;

  AppIllustrations get _illustration => switch (view) {
    MapView.fog => AppIllustrations.viewFog,
    MapView.streets => AppIllustrations.viewStreets,
    MapView.heatmap => AppIllustrations.viewHeatmap,
    MapView.voronoi => AppIllustrations.viewVoronoi,
  };

  String _name(AppLocalizations l10n) => switch (view) {
    MapView.fog => l10n.mapViewFog,
    MapView.streets => l10n.mapViewStreets,
    MapView.heatmap => l10n.mapViewHeatmap,
    MapView.voronoi => l10n.mapViewVoronoi,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: NeuSurface(
          shadows: selected
              ? shadows.inset(NeoDepth.lg)
              : shadows.raised(NeoDepth.lg),
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            spacing: 14,
            children: [
              NeuSurface(
                shadows: selected ? shadows.shade(NeoDepth.xs) : const [],
                borderRadius: BorderRadius.circular(14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AppIllustration(_illustration, size: _picture),
                ),
              ),
              Expanded(
                child: Text(
                  _name(context.l10n),
                  style: context.typography.value.copyWith(
                    color: selected ? palette.accent : null,
                  ),
                ),
              ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;
    return NeuSurface.circle(
      shadows: shadows.inset(NeoDepth.sm),
      size: 28,
      child: selected
          ? Center(
              child: NeuSurface.circle(
                shadows: shadows.shade(NeoDepth.xs),
                color: context.palette.accent,
                size: 14,
              ),
            )
          : null,
    );
  }
}
