class DailyExplorationStats {
  final String date;
  final bool openedApp;
  final double newAreaM2;
  final double distanceM;
  final int durationSeconds;
  final double walkDistanceM;
  final double bikeDistanceM;
  final double runDistanceM;
  final double otherDistanceM;
  final int newStreetsCount;

  const DailyExplorationStats({
    required this.date,
    this.openedApp = true,
    this.newAreaM2 = 0.0,
    this.distanceM = 0.0,
    this.durationSeconds = 0,
    this.walkDistanceM = 0.0,
    this.bikeDistanceM = 0.0,
    this.runDistanceM = 0.0,
    this.otherDistanceM = 0.0,
    this.newStreetsCount = 0,
  });

  DailyExplorationStats copyWith({
    String? date,
    bool? openedApp,
    double? newAreaM2,
    double? distanceM,
    int? durationSeconds,
    double? walkDistanceM,
    double? bikeDistanceM,
    double? runDistanceM,
    double? otherDistanceM,
    int? newStreetsCount,
  }) {
    return DailyExplorationStats(
      date: date ?? this.date,
      openedApp: openedApp ?? this.openedApp,
      newAreaM2: newAreaM2 ?? this.newAreaM2,
      distanceM: distanceM ?? this.distanceM,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      walkDistanceM: walkDistanceM ?? this.walkDistanceM,
      bikeDistanceM: bikeDistanceM ?? this.bikeDistanceM,
      runDistanceM: runDistanceM ?? this.runDistanceM,
      otherDistanceM: otherDistanceM ?? this.otherDistanceM,
      newStreetsCount: newStreetsCount ?? this.newStreetsCount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'date': date,
      'opened_app': openedApp ? 1 : 0,
      'new_area_m2': newAreaM2,
      'distance_m': distanceM,
      'duration_seconds': durationSeconds,
      'walk_distance_m': walkDistanceM,
      'bike_distance_m': bikeDistanceM,
      'run_distance_m': runDistanceM,
      'other_distance_m': otherDistanceM,
      'new_streets_count': newStreetsCount,
    };
  }

  factory DailyExplorationStats.fromMap(Map<String, Object?> map) {
    return DailyExplorationStats(
      date: map['date']! as String,
      openedApp: (map['opened_app'] as int? ?? 1) == 1,
      newAreaM2: (map['new_area_m2']! as num).toDouble(),
      distanceM: (map['distance_m']! as num).toDouble(),
      durationSeconds: map['duration_seconds']! as int,
      walkDistanceM: (map['walk_distance_m']! as num).toDouble(),
      bikeDistanceM: (map['bike_distance_m']! as num).toDouble(),
      runDistanceM: (map['run_distance_m']! as num).toDouble(),
      otherDistanceM: (map['other_distance_m']! as num).toDouble(),
      newStreetsCount: map['new_streets_count']! as int,
    );
  }
}
