import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/features/heatmap/heat_config.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_density.dart';
import 'package:globetrottr_front/features/heatmap/render/heat_levels.dart';

/// One colour of a heatmap scale: [at] runs from 0 (one session) to 1 (the
/// busiest places, see [HeatLevels.shareOf]).
@immutable
class HeatStop {
  const HeatStop(this.at, this.color);

  final double at;

  /// Opacity included.
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is HeatStop && other.at == at && other.color == color;

  @override
  int get hashCode => Object.hash(at, color);
}

/// How the heatmap looks. The colour of every value is baked into the tile
/// images, so any scale costs the same to paint: the session counts
/// themselves ([levels]), or a density blurred from them ([spread]).
@immutable
class HeatStyle {
  const HeatStyle({
    required this.stops,
    this.backdrop,
    this.densityPixels = 0,
    this.densityUnit = 1,
    this.densitySaturation = 50,
    this.densityContrast = 1,
  });

  /// The look of the app: a darkened map with smooth patches of density,
  /// from [AppPalette.heatRare] where a route was taken once to
  /// [AppPalette.heatBusiest] where most of the traffic is.
  factory HeatStyle.of(AppPalette palette) => HeatStyle(
    stops: [
      HeatStop(0, palette.heatRare),
      HeatStop(0.25, palette.heatLow),
      HeatStop(0.5, palette.heatMid),
      HeatStop(0.78, palette.heatHigh),
      HeatStop(1, palette.heatBusiest),
    ],
    backdrop: palette.heatBackdrop,
    densityPixels: HeatConfig.densityPixels,
    densityUnit: HeatConfig.densityUnit,
    densitySaturation: HeatConfig.densitySaturation,
    densityContrast: HeatConfig.densityContrast,
  );

  /// At least two, ordered by [HeatStop.at] from 0 to 1.
  final List<HeatStop> stops;

  /// Drawn over the whole map below the heat, to make it stand out.
  final Color? backdrop;

  /// Above 0 the counts are blurred into a density by a kernel this many
  /// tile pixels wide (about the sigma of a Gaussian), so the heatmap shows
  /// smooth patches instead of routes. The size stays the same on the
  /// screen at every zoom.
  final int densityPixels;

  /// Density of a route passed once, where the scale starts.
  final double densityUnit;

  /// Density where the scale ends.
  final double densitySaturation;

  /// Exponent of the curve along the scale (see [HeatDensityRecipe]).
  final double densityContrast;

  static final Map<HeatStyle, Uint32List> _levels = {};
  static final Map<HeatStyle, TileImageBuilder> _spreads = {};

  /// Builds tile images as a density in a background isolate; null when
  /// [densityPixels] is 0 and the images show the routes ([levels]).
  TileImageBuilder? get spread {
    if (densityPixels <= 0) return null;
    return _spreads[this] ??= _buildSpread();
  }

  /// The blur and the scale of [spread].
  HeatDensityRecipe get densityRecipe {
    final words = Uint32List(256);
    for (var step = 1; step < 256; step++) {
      final share = step / 255;
      // The lowest steps fade in, so a patch has no hard rim.
      final fade = math.min(1, share / 0.12);
      final color = colorAt(share);
      words[step] = _premultiplied(color.withValues(alpha: color.a * fade));
    }
    return HeatDensityRecipe(
      boxRadius: densityPixels,
      unit: densityUnit,
      saturation: densitySaturation,
      contrast: densityContrast,
      levels: words,
    );
  }

  TileImageBuilder _buildSpread() {
    final recipe = densityRecipe;
    return (around) => Isolate.run(() => HeatDensity.build(around, recipe));
  }

  /// The premultiplied RGBA word (little endian) of every session count
  /// 0..255; 0 is transparent.
  Uint32List get levels => _levels[this] ??= _buildLevels();

  Uint32List _buildLevels() {
    final words = Uint32List(256);
    for (var count = 1; count < 256; count++) {
      words[count] = _premultiplied(colorAt(HeatLevels.shareOf(count)!));
    }
    return words;
  }

  /// The colour at [share] of the scale.
  Color colorAt(double share) {
    if (share <= stops.first.at) return stops.first.color;
    for (var i = 1; i < stops.length; i++) {
      final to = stops[i];
      if (share > to.at) continue;
      final from = stops[i - 1];
      final t = (share - from.at) / (to.at - from.at);
      return Color.lerp(from.color, to.color, t)!;
    }
    return stops.last.color;
  }

  static int _premultiplied(Color color) {
    int channel(double value) => (value * color.a * 255).round() & 0xFF;
    final alpha = (color.a * 255).round() & 0xFF;
    return alpha << 24 |
        channel(color.b) << 16 |
        channel(color.g) << 8 |
        channel(color.r);
  }

  @override
  bool operator ==(Object other) =>
      other is HeatStyle &&
      listEquals(other.stops, stops) &&
      other.backdrop == backdrop &&
      other.densityPixels == densityPixels &&
      other.densityUnit == densityUnit &&
      other.densitySaturation == densitySaturation &&
      other.densityContrast == densityContrast;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(stops),
    backdrop,
    densityPixels,
    densityUnit,
    densitySaturation,
    densityContrast,
  );
}
