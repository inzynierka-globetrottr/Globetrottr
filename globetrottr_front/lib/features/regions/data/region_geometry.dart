import 'dart:typed_data';

/// Boundary format v2, written by `tool/regions/build_regions.py`: a varint
/// ring count, then per ring a varint point count and zigzag varint deltas
/// of longitude and latitude in 1e-5 degree, starting from 0 in every ring.
/// Rings are read with the even-odd rule, so holes and islands need no more
/// structure.
const _scale = 100000.0;

/// Rings as (longitude, latitude) points.
List<List<(double, double)>> decodeRegionGeometry(Uint8List blob) {
  final reader = _Reader(blob);
  final rings = <List<(double, double)>>[];
  for (var r = reader.varint(); r > 0; r--) {
    final ring = <(double, double)>[];
    var x = 0;
    var y = 0;
    for (var n = reader.varint(); n > 0; n--) {
      x += reader.zigzag();
      y += reader.zigzag();
      ring.add((x / _scale, y / _scale));
    }
    rings.add(ring);
  }
  return rings;
}

/// Point in polygon by ray casting over all rings, decoding on the fly.
bool regionGeometryContains(Uint8List blob, double lat, double lon) {
  final px = lon * _scale;
  final py = lat * _scale;
  final reader = _Reader(blob);
  var inside = false;
  for (var r = reader.varint(); r > 0; r--) {
    final count = reader.varint();
    if (count == 0) continue;
    var x = reader.zigzag();
    var y = reader.zigzag();
    final firstX = x;
    final firstY = y;
    for (var i = 1; i <= count; i++) {
      final int nx;
      final int ny;
      if (i < count) {
        nx = x + reader.zigzag();
        ny = y + reader.zigzag();
      } else {
        nx = firstX;
        ny = firstY;
      }
      if ((y > py) != (ny > py) && px < (nx - x) * (py - y) / (ny - y) + x) {
        inside = !inside;
      }
      x = nx;
      y = ny;
    }
  }
  return inside;
}

class _Reader {
  _Reader(this._data);

  final Uint8List _data;
  int _offset = 0;

  int varint() {
    var result = 0;
    var shift = 0;
    while (true) {
      final byte = _data[_offset++];
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
    }
  }

  int zigzag() {
    final value = varint();
    return (value >> 1) ^ -(value & 1);
  }
}
