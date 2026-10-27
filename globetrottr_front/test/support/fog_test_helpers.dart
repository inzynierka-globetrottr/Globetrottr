import 'dart:math' as math;

import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

const double krakowLat = 50.0614;
const double krakowLng = 19.9383;

/// A coordinate moved by meters north and east (accurate enough for tests).
({double lat, double lng}) offsetMeters(
  double lat,
  double lng, {
  double north = 0,
  double east = 0,
}) {
  const metersPerDegree = 111319.49;
  return (
    lat: lat + north / metersPerDegree,
    lng: lng + east / (metersPerDegree * math.cos(lat * math.pi / 180)),
  );
}

TrackLogEntry logEntry(
  String session,
  int index,
  ({double lat, double lng}) at, {
  int? id,
}) {
  return TrackLogEntry(
    id: id,
    sessionId: session,
    timestampMs: 1700000000000 + index * 1000,
    latitude: at.lat,
    longitude: at.lng,
  );
}

/// Entries of a straight walk heading east, one every [stepMeters].
List<TrackLogEntry> walkEast(
  String session, {
  int points = 20,
  double stepMeters = 10,
  double startLat = krakowLat,
  double startLng = krakowLng,
  int firstIndex = 0,
}) {
  return [
    for (var i = 0; i < points; i++)
      logEntry(
        session,
        firstIndex + i,
        offsetMeters(startLat, startLng, east: i * stepMeters),
      ),
  ];
}

Future<Map<int, FogMask>> decodeAllTiles(FogTileStorage storage, int z) async {
  final stats = await storage.stats();
  if ((stats.tilesPerLevel[z] ?? 0) == 0) return {};
  final result = <int, FogMask>{};
  final tiles = await storage.loadRange(
    z: z,
    xMin: 0,
    xMax: (1 << z) - 1,
    yMin: 0,
    yMax: (1 << z) - 1,
  );
  for (final tile in tiles) {
    result[tile.id.key] = FogTileCodec.decode(tile.flag, tile.bytes);
  }
  return result;
}

bool sameMasks(Map<int, FogMask> a, Map<int, FogMask> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null) return false;
    for (var i = 0; i < FogMask.pixels; i++) {
      if (entry.value.data[i] != other.data[i]) return false;
    }
  }
  return true;
}

FogTileId tileOf(double lat, double lng, int z) =>
    FogMercator.tileAt(lat, lng, z);
