import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

class _Box {
  const _Box(this.south, this.west, this.north, this.east);

  final double south;
  final double west;
  final double north;
  final double east;

  bool containsBox(_Box other) =>
      south <= other.south &&
      west <= other.west &&
      north >= other.north &&
      east >= other.east;

  bool containsPoint(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;
}

/// The points of the track log around what the map currently shows.
///
/// A developer aid: it lets the map display what is really stored, so it can
/// be compared with the fog that is interpolated between those points. The
/// points are queried for an area larger than the view, so panning a little
/// does not query again.
class RecordedPointsSource extends ChangeNotifier {
  RecordedPointsSource(
    this._storage, {
    this.minZoom = 14,
    this.maxPoints = 20000,
    this.padding = 0.5,
  });

  final TrackLogStorage _storage;

  /// Below this zoom the view covers too much ground to list its points.
  final double minZoom;
  final int maxPoints;

  /// How much extra area, as a share of the view, is loaded on every side.
  final double padding;

  List<TrackLogEntry> _points = const [];
  _Box? _loaded;
  int _request = 0;
  bool _disposed = false;

  List<TrackLogEntry> get points => _points;

  /// Loads the points for [camera] unless the area is already loaded.
  Future<void> ensure(MapCamera camera) async {
    if (_disposed) return;
    if (!camera.isUsableForFog || camera.zoom < minZoom) {
      clear();
      return;
    }

    final view = camera.visibleBounds;
    final needed = _Box(view.south, view.west, view.north, view.east);
    final loaded = _loaded;
    if (loaded != null && loaded.containsBox(needed)) return;

    final latPad = (view.north - view.south) * padding;
    final lngPad = (view.east - view.west) * padding;
    final box = _Box(
      view.south - latPad,
      view.west - lngPad,
      view.north + latPad,
      view.east + lngPad,
    );
    final request = ++_request;
    final found = await _storage.entriesInBounds(
      south: box.south,
      west: box.west,
      north: box.north,
      east: box.east,
      limit: maxPoints,
    );
    if (_disposed || request != _request) return;
    _points = found;
    _loaded = box;
    notifyListeners();
  }

  /// Adds a point that was just recorded, if it belongs to the loaded area.
  void add(TrackLogEntry entry) {
    final loaded = _loaded;
    if (_disposed || loaded == null) return;
    if (!loaded.containsPoint(entry.latitude, entry.longitude)) return;
    _points = [..._points, entry];
    notifyListeners();
  }

  /// Forgets everything; the next [ensure] queries again.
  void clear() {
    _request++;
    final hadPoints = _points.isNotEmpty;
    _points = const [];
    _loaded = null;
    if (hadPoints && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
