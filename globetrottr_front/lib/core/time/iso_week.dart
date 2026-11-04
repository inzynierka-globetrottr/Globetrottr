/// The ISO 8601 week of [date]: weeks start on Monday and week 1 is the one
/// holding the first Thursday of the year.
int isoWeekNumber(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final yearStart = DateTime.utc(thursday.year);
  return 1 + thursday.difference(yearStart).inDays ~/ 7;
}

/// The ISO weeks of the last [count] weeks, oldest first, ending with the
/// week of [now].
List<int> recentIsoWeeks(DateTime now, int count) {
  final today = DateTime.utc(now.year, now.month, now.day);
  return [
    for (var weeksAgo = count - 1; weeksAgo >= 0; weeksAgo--)
      isoWeekNumber(today.subtract(Duration(days: 7 * weeksAgo))),
  ];
}
