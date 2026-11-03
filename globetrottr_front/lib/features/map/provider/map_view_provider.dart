import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ways of showing what the user has discovered.
enum MapView {
  fog(isAvailable: true),
  // TODO(data): the streets and Voronoi views are planned; each is a
  // derived layer of the track log.
  streets(isAvailable: false),
  heatmap(isAvailable: true),
  voronoi(isAvailable: false);

  const MapView({required this.isAvailable});

  final bool isAvailable;
}

class MapViewNotifier extends Notifier<MapView> {
  @override
  MapView build() => MapView.fog;

  /// Switches to [view] if it exists yet; returns whether it did.
  bool select(MapView view) {
    if (!view.isAvailable) return false;
    state = view;
    return true;
  }
}

final mapViewProvider = NotifierProvider<MapViewNotifier, MapView>(
  MapViewNotifier.new,
);
