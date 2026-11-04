import 'dart:typed_data';

/// Writes geometry format v2 like `tool/regions/build_regions.py`, for test
/// fixtures. Rings are lists of (longitude, latitude).
Uint8List encodeRegionGeometry(List<List<(double, double)>> rings) {
  final out = BytesBuilder();
  void varint(int value) {
    var v = value;
    while (true) {
      final byte = v & 0x7F;
      v >>= 7;
      if (v != 0) {
        out.addByte(byte | 0x80);
      } else {
        out.addByte(byte);
        return;
      }
    }
  }

  int zigzag(int v) => (v << 1) ^ (v >> 63);

  varint(rings.length);
  for (final ring in rings) {
    varint(ring.length);
    var px = 0;
    var py = 0;
    for (final (lon, lat) in ring) {
      final x = (lon * 100000).round();
      final y = (lat * 100000).round();
      varint(zigzag(x - px));
      varint(zigzag(y - py));
      px = x;
      py = y;
    }
  }
  return out.toBytes();
}

/// A closed rectangle as one ring.
List<List<(double, double)>> rectangle({
  required double minLon,
  required double minLat,
  required double maxLon,
  required double maxLat,
}) => [
  [
    (minLon, minLat),
    (maxLon, minLat),
    (maxLon, maxLat),
    (minLon, maxLat),
    (minLon, minLat),
  ],
];
