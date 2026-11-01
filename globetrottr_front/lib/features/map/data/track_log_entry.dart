/// One recorded GPS fix. Unlike `PendingPoint` it is never deleted by a
/// sync, so routes, daily totals and pace can always be reconstructed.
class TrackLogEntry {
  const TrackLogEntry({
    required this.sessionId,
    required this.timestampMs,
    required this.latitude,
    required this.longitude,
    this.id,
    this.accuracy,
    this.speed,
  });

  final int? id;
  final String sessionId;

  /// Time of the GPS fix in milliseconds since the Unix epoch (UTC).
  final int timestampMs;
  final double latitude;
  final double longitude;

  /// Horizontal accuracy in meters, when the platform reports it.
  final double? accuracy;

  /// Speed in meters per second, when the platform reports it.
  final double? speed;

  TrackLogEntry withId(int id) => TrackLogEntry(
    id: id,
    sessionId: sessionId,
    timestampMs: timestampMs,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    speed: speed,
  );
}

class TrackSessionSummary {
  const TrackSessionSummary({
    required this.sessionId,
    required this.startMs,
    required this.endMs,
    required this.pointCount,
  });

  final String sessionId;
  final int startMs;
  final int endMs;
  final int pointCount;
}
