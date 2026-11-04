import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';

void main() {
  group('Duel', () {
    test('the larger value leads', () {
      expect(const Duel(me: 14, friend: 9).leader, DuelSide.me);
      expect(const Duel(me: 0.9, friend: 1.2).leader, DuelSide.friend);
    });

    test('a tie or a missing value has no leader', () {
      expect(const Duel(me: 3, friend: 3).leader, isNull);
      expect(const Duel(me: 3).leader, isNull);
      expect(const Duel().leader, isNull);
    });

    test('my share of both values fills the bar', () {
      expect(const Duel(me: 3, friend: 1).myShare, 0.75);
      expect(const Duel(me: 0, friend: 0).myShare, isNull);
      expect(const Duel(friend: 2).myShare, isNull);
    });
  });

  group('AreaSplit', () {
    test('parts are shares of the area discovered by either', () {
      const split = AreaSplit(onlyMeKm2: 4, sharedKm2: 1, onlyFriendKm2: 5);

      expect(split.onlyMe, closeTo(0.4, 1e-9));
      expect(split.shared, closeTo(0.1, 1e-9));
      expect(split.onlyFriend, closeTo(0.5, 1e-9));
    });

    test('nothing discovered gives no shares', () {
      const split = AreaSplit(onlyMeKm2: 0, sharedKm2: 0, onlyFriendKm2: 0);

      expect(split.isEmpty, isTrue);
      expect(split.onlyMe, 0);
    });
  });
}
