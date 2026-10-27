import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:meta/meta.dart';

@immutable
class FogRenderOptions {
  const FogRenderOptions({
    this.opacity = FogConfig.fogOpacity,
    this.softEdge = true,
    this.softEdgeMeters = 4.0,
    this.maxBlurSigma = 3.0,
    this.showGrid = false,
    this.rawPixels = false,
  });

  /// Opacity of the fog where nothing is discovered.
  final double opacity;

  /// Blurs the rim of the fog so it looks continuous instead of pixelated.
  final bool softEdge;

  /// Rough width of the soft rim on the ground.
  final double softEdgeMeters;

  /// Upper bound of the blur in screen pixels, to keep drawing cheap.
  final double maxBlurSigma;

  /// Developer aid: outlines the fog tiles that are being drawn and names
  /// them `z/x/y`.
  final bool showGrid;

  /// Developer aid: shows the stored fog pixels exactly as they are. No blur,
  /// no smoothing between pixels, no live disc around the player, and thin
  /// lines between the pixels once they are large enough on the screen.
  final bool rawPixels;

  FogRenderOptions copyWith({
    double? opacity,
    bool? softEdge,
    double? softEdgeMeters,
    double? maxBlurSigma,
    bool? showGrid,
    bool? rawPixels,
  }) {
    return FogRenderOptions(
      opacity: opacity ?? this.opacity,
      softEdge: softEdge ?? this.softEdge,
      softEdgeMeters: softEdgeMeters ?? this.softEdgeMeters,
      maxBlurSigma: maxBlurSigma ?? this.maxBlurSigma,
      showGrid: showGrid ?? this.showGrid,
      rawPixels: rawPixels ?? this.rawPixels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FogRenderOptions &&
      other.opacity == opacity &&
      other.softEdge == softEdge &&
      other.softEdgeMeters == softEdgeMeters &&
      other.maxBlurSigma == maxBlurSigma &&
      other.showGrid == showGrid &&
      other.rawPixels == rawPixels;

  @override
  int get hashCode => Object.hash(
    opacity,
    softEdge,
    softEdgeMeters,
    maxBlurSigma,
    showGrid,
    rawPixels,
  );
}
