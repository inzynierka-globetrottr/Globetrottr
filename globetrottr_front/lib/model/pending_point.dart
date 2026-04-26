class PendingPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final int timestamp;

  PendingPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory PendingPoint.fromMap(Map<String, dynamic> map) {
    return PendingPoint(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
    );
  }
}
