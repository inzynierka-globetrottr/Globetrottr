import 'package:meta/meta.dart';

@immutable
class FogRenderOptions {
  const FogRenderOptions({
    this.softEdge = true,
    this.softEdgeMeters = 4.0,
    this.showGrid = false,
    this.rawPixels = false,
  });

  /// Blurs the rim of the fog so it looks continuous instead of pixelated.
  final bool softEdge;

  /// Rough width of the soft rim on the ground.
  final double softEdgeMeters;

  /// Developer aid: outlines the fog tiles that are being drawn and names
  /// them `z/x/y`.
  final bool showGrid;

  /// Developer aid: shows the stored fog pixels exactly as they are. No blur,
  /// no smoothing between pixels, no live disc around the player, and thin
  /// lines between the pixels once they are large enough on the screen.
  final bool rawPixels;

  FogRenderOptions copyWith({
    bool? softEdge,
    double? softEdgeMeters,
    bool? showGrid,
    bool? rawPixels,
  }) {
    return FogRenderOptions(
      softEdge: softEdge ?? this.softEdge,
      softEdgeMeters: softEdgeMeters ?? this.softEdgeMeters,
      showGrid: showGrid ?? this.showGrid,
      rawPixels: rawPixels ?? this.rawPixels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FogRenderOptions &&
      other.softEdge == softEdge &&
      other.softEdgeMeters == softEdgeMeters &&
      other.showGrid == showGrid &&
      other.rawPixels == rawPixels;

  @override
  int get hashCode => Object.hash(
    softEdge,
    softEdgeMeters,
    showGrid,
    rawPixels,
  );
}
