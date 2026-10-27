import 'dart:math' as math;

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';

class RouteStats {
  const RouteStats({
    required this.distanceMeters,
    required this.elapsed,
    required this.movingTime,
  });

  final double distanceMeters;

  /// Time between the first and the last fix.
  final Duration elapsed;

  /// Time covered by fixes that follow each other closely; long signal gaps
  /// (tunnels, a paused phone) are left out so they do not ruin the pace.
  final Duration movingTime;

  double? get averageSpeedMps {
    if (distanceMeters <= 0 || movingTime == Duration.zero) return null;
    return distanceMeters / (movingTime.inMicroseconds / 1e6);
  }

  Duration? get pacePerKm {
    final speed = averageSpeedMps;
    if (speed == null) return null;
    return Duration(milliseconds: (1000 / speed * 1000).round());
  }
}

class DaySummary {
  const DaySummary({
    required this.day,
    required this.distanceMeters,
    required this.movingTime,
    required this.sessionIds,
    required this.pointCount,
  });

  /// Midnight of the day, expressed as a UTC [DateTime] for stable keys.
  final DateTime day;
  final double distanceMeters;
  final Duration movingTime;
  final Set<String> sessionIds;
  final int pointCount;
}

abstract final class TrackAnalytics {
  static const Duration defaultMaxGap = Duration(minutes: 5);
  static const double _earthRadiusMeters = 6371008.8;

  static double distanceMeters(List<TrackLogEntry> entries) {
    var total = 0.0;
    for (var i = 1; i < entries.length; i++) {
      total += _haversine(entries[i - 1], entries[i]);
    }
    return total;
  }

  /// Statistics of one continuous route; [entries] must be in time order.
  static RouteStats statsFor(
    List<TrackLogEntry> entries, {
    Duration maxGap = defaultMaxGap,
  }) {
    if (entries.length < 2) {
      return const RouteStats(
        distanceMeters: 0,
        elapsed: Duration.zero,
        movingTime: Duration.zero,
      );
    }
    var moving = 0;
    for (var i = 1; i < entries.length; i++) {
      final delta = entries[i].timestampMs - entries[i - 1].timestampMs;
      if (delta > 0 && delta <= maxGap.inMilliseconds) moving += delta;
    }
    return RouteStats(
      distanceMeters: distanceMeters(entries),
      elapsed: Duration(
        milliseconds: entries.last.timestampMs - entries.first.timestampMs,
      ),
      movingTime: Duration(milliseconds: moving),
    );
  }

  static Map<DateTime, List<TrackLogEntry>> splitByDay(
    List<TrackLogEntry> entries, {
    required Duration utcOffset,
  }) {
    final days = <DateTime, List<TrackLogEntry>>{};
    for (final entry in entries) {
      days.putIfAbsent(_dayOf(entry, utcOffset), () => []).add(entry);
    }
    final keys = days.keys.toList()..sort();
    return {for (final key in keys) key: days[key]!};
  }

  /// Per-day totals. A leg belongs to the day of the fix that ended it, and
  /// legs are only measured inside one session.
  static List<DaySummary> dailySummaries(
    List<TrackLogEntry> entries, {
    required Duration utcOffset,
    Duration maxGap = defaultMaxGap,
  }) {
    final distance = <DateTime, double>{};
    final moving = <DateTime, int>{};
    final sessions = <DateTime, Set<String>>{};
    final points = <DateTime, int>{};

    final bySession = <String, List<TrackLogEntry>>{};
    for (final entry in entries) {
      bySession.putIfAbsent(entry.sessionId, () => []).add(entry);
    }

    for (final group in bySession.values) {
      group.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
      for (var i = 0; i < group.length; i++) {
        final day = _dayOf(group[i], utcOffset);
        points.update(day, (n) => n + 1, ifAbsent: () => 1);
        sessions.putIfAbsent(day, () => {}).add(group[i].sessionId);
        distance.putIfAbsent(day, () => 0);
        moving.putIfAbsent(day, () => 0);
        if (i == 0) continue;
        distance[day] = distance[day]! + _haversine(group[i - 1], group[i]);
        final delta = group[i].timestampMs - group[i - 1].timestampMs;
        if (delta > 0 && delta <= maxGap.inMilliseconds) {
          moving[day] = moving[day]! + delta;
        }
      }
    }

    final days = distance.keys.toList()..sort();
    return [
      for (final day in days)
        DaySummary(
          day: day,
          distanceMeters: distance[day]!,
          movingTime: Duration(milliseconds: moving[day]!),
          sessionIds: sessions[day]!,
          pointCount: points[day]!,
        ),
    ];
  }

  static DateTime _dayOf(TrackLogEntry entry, Duration utcOffset) {
    final shifted = DateTime.fromMillisecondsSinceEpoch(
      entry.timestampMs + utcOffset.inMilliseconds,
      isUtc: true,
    );
    return DateTime.utc(shifted.year, shifted.month, shifted.day);
  }

  static double _haversine(TrackLogEntry a, TrackLogEntry b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }
}
