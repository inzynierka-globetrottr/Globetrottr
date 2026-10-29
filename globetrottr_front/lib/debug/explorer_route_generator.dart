import 'dart:math' as math;

import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:latlong2/latlong.dart';

/// A rectangle a continent journey keeps to.
class ExplorerRegion {
  const ExplorerRegion(
    this.name, {
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  static const europe = ExplorerRegion(
    'Europe',
    south: 36,
    west: -9,
    north: 70,
    east: 40,
  );
  static const asia = ExplorerRegion(
    'Asia',
    south: 10,
    west: 60,
    north: 55,
    east: 140,
  );
  static const africa = ExplorerRegion(
    'Africa',
    south: -34,
    west: -17,
    north: 35,
    east: 50,
  );
  static const northAmerica = ExplorerRegion(
    'North America',
    south: 25,
    west: -125,
    north: 60,
    east: -70,
  );
  static const southAmerica = ExplorerRegion(
    'South America',
    south: -50,
    west: -78,
    north: 10,
    east: -36,
  );
  static const australia = ExplorerRegion(
    'Australia',
    south: -38,
    west: 114,
    north: -12,
    east: 153,
  );

  static const List<ExplorerRegion> all = [
    europe,
    asia,
    africa,
    northAmerica,
    southAmerica,
    australia,
  ];

  final String name;
  final double south;
  final double west;
  final double north;
  final double east;

  LatLng get center => LatLng((south + north) / 2, (west + east) / 2);

  bool contains(LatLng point) =>
      point.latitude >= south &&
      point.latitude <= north &&
      point.longitude >= west &&
      point.longitude <= east;
}

/// Synthetic journeys of a keen explorer: long motorway stretches, winding
/// roads and city street grids, one session per trip, one trip per day.
/// Used to stress the fog with realistic, connected, large amounts of data.
abstract final class ExplorerRouteGenerator {
  static List<TrackLogEntry> generate({
    required LatLng start,
    required double totalKm,
    double spacingMeters = 10,
    int seed = 7,
  }) {
    final journey = ExplorerJourney(
      start: start,
      totalKm: totalKm,
      spacingMeters: spacingMeters,
      seed: seed,
    );
    final entries = <TrackLogEntry>[];
    while (!journey.isDone) {
      entries.addAll(journey.next());
    }
    return entries;
  }
}

/// An explorer journey produced chunk by chunk, so even 100 000 km (millions
/// of fixes) never have to be held in memory at once.
///
/// With a [region] every trip heads for a random destination inside it and a
/// new one is picked on arrival, so the journey crosses the whole continent.
/// With [spacingFollowsSpeed] the fixes are one second apart (but at least
/// [spacingMeters]), like a GPS logging once a second.
class ExplorerJourney {
  ExplorerJourney({
    required LatLng start,
    required double totalKm,
    this.spacingMeters = 10,
    this.spacingFollowsSpeed = false,
    this.region,
    int seed = 7,
  }) : totalKm = math.max(0, totalKm),
       _random = math.Random(seed),
       _remainingMeters = math.max(0, totalKm) * 1000 {
    final from = region == null || region!.contains(start)
        ? start
        : region!.center;
    _lat = from.latitude;
    _lng = from.longitude;
  }

  static const double _metersPerDegree = 111319.49;
  static const double _arrivalMeters = 30000;
  static final int _firstDay = DateTime.utc(
    2026,
    1,
    1,
    8,
  ).millisecondsSinceEpoch;

  final double totalKm;
  final double spacingMeters;
  final bool spacingFollowsSpeed;
  final ExplorerRegion? region;
  final math.Random _random;

  double _remainingMeters;
  double _doneMeters = 0;
  late double _lat;
  late double _lng;
  int _day = 0;
  bool _inTrip = false;
  double _tripMeters = 0;
  double _travelled = 0;
  double _segmentLeft = 0;
  _Segment _segment = _Segment.highway;
  double _heading = 0;
  int _timestamp = 0;
  String _session = '';
  LatLng? _destination;

  bool get isDone => !_inTrip && _remainingMeters <= 0;

  double get travelledKm => _doneMeters / 1000;

  /// The next fixes of the journey, at most [maxPoints]; empty once done.
  List<TrackLogEntry> next({int maxPoints = 50000}) {
    final entries = <TrackLogEntry>[];
    while (entries.length < maxPoints) {
      if (!_inTrip) {
        if (_remainingMeters <= 0) break;
        _startTrip();
      }
      entries.add(_step());
      if (_travelled >= _tripMeters) _inTrip = false;
    }
    return entries;
  }

  void _startTrip() {
    _tripMeters = math.min(
      _remainingMeters,
      (20 + _random.nextDouble() * 130) * 1000,
    );
    _remainingMeters -= _tripMeters;

    _lat += (_random.nextDouble() - 0.5) * 0.04;
    _lng += (_random.nextDouble() - 0.5) * 0.06;
    _heading = _random.nextDouble() * 2 * math.pi;
    if (region != null) {
      if (_destination == null || _metersTo(_destination!) < _arrivalMeters) {
        _destination = _randomDestination();
      }
      _heading = _bearingTo(_destination!) + (_heading - math.pi) / 3;
    }
    _timestamp = _firstDay + _day * Duration.millisecondsPerDay;
    _day++;
    _session = 'trip_$_day';
    _travelled = 0;
    _segmentLeft = 0;
    _segment = _Segment.highway;
    _inTrip = true;
  }

  TrackLogEntry _step() {
    if (_segmentLeft <= 0) {
      _segment = _Segment.values[_random.nextInt(_Segment.values.length)];
      _segmentLeft =
          _segment.minMeters +
          _random.nextDouble() * (_segment.maxMeters - _segment.minMeters);
      if (_segment == _Segment.city) {
        _heading = (_heading / (math.pi / 2)).round() * (math.pi / 2);
      }
    }

    final speed = _segment.speed * (0.85 + _random.nextDouble() * 0.3);
    final entry = TrackLogEntry(
      sessionId: _session,
      timestampMs: _timestamp,
      latitude: _lat,
      longitude: _lng,
      accuracy: 4 + _random.nextDouble() * 6,
      speed: speed,
    );
    final step = spacingFollowsSpeed
        ? math.max(spacingMeters, speed)
        : spacingMeters;

    if (_segment == _Segment.city) {
      if (_random.nextDouble() < step / 180) {
        var turn = _random.nextBool() ? 1 : -1;
        final destination = _destination;
        if (destination != null && _random.nextDouble() < 0.7) {
          turn = _turnTowards(destination) >= 0 ? 1 : -1;
        }
        _heading += turn * math.pi / 2;
      }
    } else {
      _heading += (_random.nextDouble() - 0.5) * _segment.wobble;
      final destination = _destination;
      if (destination != null) {
        _heading += _turnTowards(destination) * math.min(1, step / 2000);
      }
    }

    _lat += math.cos(_heading) * step / _metersPerDegree;
    _lng +=
        math.sin(_heading) *
        step /
        (_metersPerDegree * math.cos(_lat * math.pi / 180));
    final bounds = region;
    if (bounds != null) {
      _lat = _lat.clamp(bounds.south, bounds.north);
      _lng = _lng.clamp(bounds.west, bounds.east);
      if (_metersTo(_destination!) < _arrivalMeters) {
        _destination = _randomDestination();
      }
    } else {
      _lat = _lat.clamp(-80.0, 80.0);
      _lng = ((_lng + 180) % 360) - 180;
    }

    _timestamp += (step / speed * 1000).round();
    _travelled += step;
    _doneMeters += step;
    _segmentLeft -= step;
    return entry;
  }

  LatLng _randomDestination() {
    final r = region!;
    return LatLng(
      r.south + _random.nextDouble() * (r.north - r.south),
      r.west + _random.nextDouble() * (r.east - r.west),
    );
  }

  /// Compass bearing (clockwise from north, radians) on a local flat map.
  double _bearingTo(LatLng target) {
    final dy = target.latitude - _lat;
    final dx = (target.longitude - _lng) * math.cos(_lat * math.pi / 180);
    return math.atan2(dx, dy);
  }

  /// Signed angle from the current heading to [target], in (-pi, pi].
  double _turnTowards(LatLng target) {
    final diff = _bearingTo(target) - _heading;
    return (diff + math.pi) % (2 * math.pi) - math.pi;
  }

  double _metersTo(LatLng target) {
    final dy = (target.latitude - _lat) * _metersPerDegree;
    final dx =
        (target.longitude - _lng) *
        _metersPerDegree *
        math.cos(_lat * math.pi / 180);
    return math.sqrt(dx * dx + dy * dy);
  }
}

enum _Segment {
  highway(25, 0.01, 20000, 80000),
  winding(14, 0.25, 3000, 15000),
  city(5, 0, 2000, 10000);

  const _Segment(this.speed, this.wobble, this.minMeters, this.maxMeters);

  final double speed;
  final double wobble;
  final double minMeters;
  final double maxMeters;
}
