class PendingPoint {
  final int? id;
  final String sessionId;
  final double latitude;
  final double longitude;
  final int timestamp;

  PendingPoint({
    this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory PendingPoint.fromMap(Map<String, dynamic> map) {
    return PendingPoint(
      id: map['id'],
      sessionId: map['sessionId'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
    );
  }
}
