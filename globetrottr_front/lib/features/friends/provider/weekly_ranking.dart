/// One person in the "this week" strip.
class WeeklyEntry {
  const WeeklyEntry({
    required this.username,
    required this.weeklyKm2,
    this.isMe = false,
    this.avatarUrl,
    this.ringFill = 0,
  });

  final String username;

  /// Area discovered this week; null while there is no data.
  final double? weeklyKm2;
  final bool isMe;
  final String? avatarUrl;

  /// How much of the ring is drawn, 1 for the leader of the week.
  final double ringFill;

  WeeklyEntry _withFill(double fill) => WeeklyEntry(
    username: username,
    weeklyKm2: weeklyKm2,
    isMe: isMe,
    avatarUrl: avatarUrl,
    ringFill: fill,
  );
}

/// The user and every friend who discovered something this week, the
/// largest area first.
List<WeeklyEntry> weeklyRanking({
  required WeeklyEntry me,
  required List<WeeklyEntry> friends,
}) {
  double area(WeeklyEntry e) => e.weeklyKm2 ?? 0;

  final entries = [
    me,
    for (final friend in friends)
      if (area(friend) > 0) friend,
  ]..sort((a, b) => area(b).compareTo(area(a)));

  final leader = entries.isEmpty ? 0.0 : area(entries.first);
  return [
    for (final e in entries) e._withFill(leader > 0 ? area(e) / leader : 0),
  ];
}
