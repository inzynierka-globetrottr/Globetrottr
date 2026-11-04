/// The Mondays that start the last [count] weeks, oldest first, ending with
/// the week of [now]. Local midnights; the constructor carries day overflow
/// into the month, so a daylight saving change cannot shift a day.
List<DateTime> recentWeekStarts(DateTime now, int count) {
  final monday = now.day - (now.weekday - DateTime.monday);
  return [
    for (var weeksAgo = count - 1; weeksAgo >= 0; weeksAgo--)
      DateTime(now.year, now.month, monday - 7 * weeksAgo),
  ];
}
