import 'dart:io';
import 'dart:typed_data';

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

/// Compact storage of the GPS fixes of one session.
///
/// Format version 1 (language neutral, so a backend can read it as is):
/// - byte 0 is the format version, the rest is a zlib stream (RFC 1950);
/// - the stream holds the count of points as a varint, then five columns of
///   `count` varints each, in this order: time, latitude, longitude,
///   accuracy, speed;
/// - every column stores the difference to the previous value (the first one
///   to zero), as a zigzag varint (little endian base 128, zigzag turns
///   small negative numbers into small unsigned ones);
/// - time is in milliseconds since the Unix epoch, positions are degrees
///   times 10^7 (a bit over one centimeter), accuracy is in tenths of a
///   meter plus one and speed in hundredths of a meter per second plus one,
///   where 0 means "unknown".
///
/// Grouping the values by column keeps similar numbers next to each other,
/// which is what lets zlib shrink a walk to a few bytes per point.
abstract final class TrackBlockCodec {
  static const int formatVersion = 1;

  static const double _positionScale = 1e7;
  static const double _accuracyScale = 10;
  static const double _speedScale = 100;

  /// The value a fix has once it went through the block format. Applied to
  /// every fix before it is stored and used for the fog, so the fog redrawn
  /// from the log is identical to the fog drawn live.
  static TrackLogEntry quantize(TrackLogEntry entry) {
    final accuracy = _accuracy(entry.accuracy);
    final speed = _speed(entry.speed);
    return TrackLogEntry(
      id: entry.id,
      sessionId: entry.sessionId,
      timestampMs: entry.timestampMs,
      latitude: _position(entry.latitude, 'latitude') / _positionScale,
      longitude: _position(entry.longitude, 'longitude') / _positionScale,
      accuracy: accuracy == 0 ? null : (accuracy - 1) / _accuracyScale,
      speed: speed == 0 ? null : (speed - 1) / _speedScale,
    );
  }

  static int _position(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be a real number');
    }
    return (value * _positionScale).round();
  }

  static int _accuracy(double? value) {
    if (value == null || !value.isFinite || value < 0) return 0;
    return (value * _accuracyScale).round() + 1;
  }

  static int _speed(double? value) {
    if (value == null || !value.isFinite || value < 0) return 0;
    return (value * _speedScale).round() + 1;
  }

  static Uint8List encode(List<TrackLogEntry> entries) {
    final payload = BytesBuilder();
    _write(payload, entries.length);
    final columns = <int Function(TrackLogEntry)>[
      (e) => e.timestampMs,
      (e) => _position(e.latitude, 'latitude'),
      (e) => _position(e.longitude, 'longitude'),
      (e) => _accuracy(e.accuracy),
      (e) => _speed(e.speed),
    ];
    for (final column in columns) {
      var previous = 0;
      for (final entry in entries) {
        final value = column(entry);
        _write(payload, value - previous);
        previous = value;
      }
    }
    final packed = ZLibCodec(level: 9).encode(payload.toBytes());
    final out = Uint8List(packed.length + 1);
    out[0] = formatVersion;
    out.setRange(1, out.length, packed);
    return out;
  }

  /// The fixes of a block, numbered from [firstId] in order.
  static List<TrackLogEntry> decode(
    Uint8List bytes, {
    required String sessionId,
    required int firstId,
  }) {
    if (bytes.isEmpty || bytes[0] != formatVersion) {
      throw FormatException(
        'Unknown track block version: ${bytes.isEmpty ? 'none' : bytes[0]}',
      );
    }
    final payload = Uint8List.fromList(
      ZLibCodec().decode(Uint8List.sublistView(bytes, 1)),
    );
    final cursor = _Cursor(payload);
    final count = _read(cursor);
    if (count < 0 || count > payload.length) {
      throw const FormatException('Corrupted track block');
    }

    List<int> column() {
      final values = List<int>.filled(count, 0);
      var previous = 0;
      for (var i = 0; i < count; i++) {
        previous += _read(cursor);
        values[i] = previous;
      }
      return values;
    }

    final times = column();
    final latitudes = column();
    final longitudes = column();
    final accuracies = column();
    final speeds = column();
    return [
      for (var i = 0; i < count; i++)
        TrackLogEntry(
          id: firstId + i,
          sessionId: sessionId,
          timestampMs: times[i],
          latitude: latitudes[i] / _positionScale,
          longitude: longitudes[i] / _positionScale,
          accuracy: accuracies[i] == 0
              ? null
              : (accuracies[i] - 1) / _accuracyScale,
          speed: speeds[i] == 0 ? null : (speeds[i] - 1) / _speedScale,
        ),
    ];
  }

  /// Smallest box around [entries], in the values they will be restored as.
  static ({double south, double west, double north, double east}) boundsOf(
    List<TrackLogEntry> entries,
  ) {
    var south = double.infinity;
    var north = double.negativeInfinity;
    var west = double.infinity;
    var east = double.negativeInfinity;
    for (final e in entries) {
      final lat = _position(e.latitude, 'latitude') / _positionScale;
      final lng = _position(e.longitude, 'longitude') / _positionScale;
      if (lat < south) south = lat;
      if (lat > north) north = lat;
      if (lng < west) west = lng;
      if (lng > east) east = lng;
    }
    return (south: south, west: west, north: north, east: east);
  }

  static ({int start, int end}) timeRangeOf(List<TrackLogEntry> entries) {
    var start = entries.first.timestampMs;
    var end = start;
    for (final e in entries) {
      if (e.timestampMs < start) start = e.timestampMs;
      if (e.timestampMs > end) end = e.timestampMs;
    }
    return (start: start, end: end);
  }

  static void _write(BytesBuilder out, int value) {
    var unsigned = (value << 1) ^ (value >> 63);
    while ((unsigned & ~0x7f) != 0) {
      out.addByte((unsigned & 0x7f) | 0x80);
      unsigned >>>= 7;
    }
    out.addByte(unsigned);
  }

  static int _read(_Cursor cursor) {
    var shift = 0;
    var unsigned = 0;
    while (true) {
      if (cursor.position >= cursor.bytes.length || shift > 63) {
        throw const FormatException('Corrupted track block');
      }
      final byte = cursor.bytes[cursor.position++];
      unsigned |= (byte & 0x7f) << shift;
      if (byte < 0x80) break;
      shift += 7;
    }
    return (unsigned >>> 1) ^ -(unsigned & 1);
  }
}

class _Cursor {
  _Cursor(this.bytes);

  final Uint8List bytes;
  int position = 0;
}
