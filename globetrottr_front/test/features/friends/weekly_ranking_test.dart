import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/friends/provider/weekly_ranking.dart';

void main() {
  WeeklyEntry entry(String name, double? km2, {bool isMe = false}) =>
      WeeklyEntry(username: name, weeklyKm2: km2, isMe: isMe);

  test('friends who discovered nothing this week are left out', () {
    final ranking = weeklyRanking(
      me: entry('ja', 0.61, isMe: true),
      friends: [entry('marek', 0.92), entry('jan', 0), entry('kuba', null)],
    );

    expect(ranking.map((e) => e.username), ['marek', 'ja']);
  });

  test('the user is always in, even without any data', () {
    final ranking = weeklyRanking(
      me: entry('ja', null, isMe: true),
      friends: [],
    );

    expect(ranking.single.isMe, isTrue);
  });

  test('the most discovered area comes first', () {
    final ranking = weeklyRanking(
      me: entry('ja', 0.61, isMe: true),
      friends: [entry('john', 0.11), entry('marek', 0.92), entry('jan', 0.40)],
    );

    expect(ranking.map((e) => e.username), ['marek', 'ja', 'jan', 'john']);
  });

  test('each ring is filled relative to the leader', () {
    final ranking = weeklyRanking(
      me: entry('ja', 0.46, isMe: true),
      friends: [entry('marek', 0.92)],
    );

    expect(ranking[0].ringFill, 1);
    expect(ranking[1].ringFill, closeTo(0.5, 1e-9));
  });

  test('without data the rings stay empty', () {
    final ranking = weeklyRanking(
      me: entry('ja', null, isMe: true),
      friends: [],
    );

    expect(ranking.single.ringFill, 0);
  });
}
