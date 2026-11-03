class UserRegionStats {
  final int regionId;
  final double discoveredAreaM2;
  final double discoveryPercentage;
  final int? firstVisitMs;
  final int? lastVisitMs;
  final int visitsCount;
  final int timeSpentSeconds;

  const UserRegionStats({
    required this.regionId,
    required this.discoveredAreaM2,
    required this.discoveryPercentage,
    this.firstVisitMs,
    this.lastVisitMs,
    this.visitsCount = 0,
    this.timeSpentSeconds = 0,
  });

  UserRegionStats copyWith({
    int? regionId,
    double? discoveredAreaM2,
    double? discoveryPercentage,
    int? firstVisitMs,
    int? lastVisitMs,
    int? visitsCount,
    int? timeSpentSeconds,
  }) {
    return UserRegionStats(
      regionId: regionId ?? this.regionId,
      discoveredAreaM2: discoveredAreaM2 ?? this.discoveredAreaM2,
      discoveryPercentage: discoveryPercentage ?? this.discoveryPercentage,
      firstVisitMs: firstVisitMs ?? this.firstVisitMs,
      lastVisitMs: lastVisitMs ?? this.lastVisitMs,
      visitsCount: visitsCount ?? this.visitsCount,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'region_id': regionId,
      'discovered_area_m2': discoveredAreaM2,
      'discovery_percentage': discoveryPercentage,
      'first_visit_ms': firstVisitMs,
      'last_visit_ms': lastVisitMs,
      'visits_count': visitsCount,
      'time_spent_seconds': timeSpentSeconds,
    };
  }

  factory UserRegionStats.fromMap(Map<String, Object?> map) {
    return UserRegionStats(
      regionId: map['region_id']! as int,
      discoveredAreaM2: (map['discovered_area_m2']! as num).toDouble(),
      discoveryPercentage: (map['discovery_percentage']! as num).toDouble(),
      firstVisitMs: map['first_visit_ms'] as int?,
      lastVisitMs: map['last_visit_ms'] as int?,
      visitsCount: (map['visits_count'] as int?) ?? 0,
      timeSpentSeconds: (map['time_spent_seconds'] as int?) ?? 0,
    );
  }
}
