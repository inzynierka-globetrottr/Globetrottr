class Quest {
  final int id;
  final String title;
  final String type;
  final int rewardPoints;
  final double progress;
  final bool isStarted; // NOWE
  final bool isCompleted;

  Quest({
    required this.id, required this.title, required this.type,
    required this.rewardPoints, required this.progress,
    required this.isStarted, required this.isCompleted,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      rewardPoints: json['rewardPoints'],
      progress: (json['progress'] as num).toDouble(),
      isStarted: json['isStarted'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}