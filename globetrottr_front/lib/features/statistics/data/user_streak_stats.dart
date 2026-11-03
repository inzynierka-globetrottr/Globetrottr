class UserStreakStats {
  final int currentOpenStreak;
  final int maxOpenStreak;
  final String? lastOpenDate;
  final int currentRecordingStreak;
  final int maxRecordingStreak;
  final String? lastRecordingDate;

  const UserStreakStats({
    required this.currentOpenStreak,
    required this.maxOpenStreak,
    required this.lastOpenDate,
    required this.currentRecordingStreak,
    required this.maxRecordingStreak,
    required this.lastRecordingDate,
  });

  static const empty = UserStreakStats(
    currentOpenStreak: 0,
    maxOpenStreak: 0,
    lastOpenDate: null,
    currentRecordingStreak: 0,
    maxRecordingStreak: 0,
    lastRecordingDate: null,
  );

  UserStreakStats copyWith({
    int? currentOpenStreak,
    int? maxOpenStreak,
    String? lastOpenDate,
    int? currentRecordingStreak,
    int? maxRecordingStreak,
    String? lastRecordingDate,
  }) {
    return UserStreakStats(
      currentOpenStreak: currentOpenStreak ?? this.currentOpenStreak,
      maxOpenStreak: maxOpenStreak ?? this.maxOpenStreak,
      lastOpenDate: lastOpenDate ?? this.lastOpenDate,
      currentRecordingStreak:
          currentRecordingStreak ?? this.currentRecordingStreak,
      maxRecordingStreak: maxRecordingStreak ?? this.maxRecordingStreak,
      lastRecordingDate: lastRecordingDate ?? this.lastRecordingDate,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'current_open_streak': currentOpenStreak,
      'max_open_streak': maxOpenStreak,
      'last_open_date': lastOpenDate,
      'current_recording_streak': currentRecordingStreak,
      'max_recording_streak': maxRecordingStreak,
      'last_recording_date': lastRecordingDate,
    };
  }

  factory UserStreakStats.fromMap(Map<String, Object?> map) {
    return UserStreakStats(
      currentOpenStreak: map['current_open_streak']! as int,
      maxOpenStreak: map['max_open_streak']! as int,
      lastOpenDate: map['last_open_date'] as String?,
      currentRecordingStreak: map['current_recording_streak']! as int,
      maxRecordingStreak: map['max_recording_streak']! as int,
      lastRecordingDate: map['last_recording_date'] as String?,
    );
  }
}
