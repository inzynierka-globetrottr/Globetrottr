import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quest_level_provider.dart';

enum DuelSide { me, friend }

/// One value compared between the user and a friend; null when unknown.
@immutable
class Duel {
  const Duel({this.me, this.friend});

  final num? me;
  final num? friend;

  /// Who has more; null on a tie or while a value is unknown.
  DuelSide? get leader {
    final me = this.me;
    final friend = this.friend;
    if (me == null || friend == null || me == friend) return null;
    return me > friend ? DuelSide.me : DuelSide.friend;
  }

  /// The user's part of both values, 0 to 1; null while it cannot be told.
  double? get myShare {
    final me = this.me;
    final friend = this.friend;
    if (me == null || friend == null || me + friend <= 0) return null;
    return me / (me + friend);
  }
}

/// The area discovered by the user or the friend, split into the parts only
/// one of them has seen and the part both have.
@immutable
class AreaSplit {
  const AreaSplit({
    required this.onlyMeKm2,
    required this.sharedKm2,
    required this.onlyFriendKm2,
  });

  final double onlyMeKm2;
  final double sharedKm2;
  final double onlyFriendKm2;

  double get _total => onlyMeKm2 + sharedKm2 + onlyFriendKm2;

  bool get isEmpty => _total <= 0;

  double get onlyMe => isEmpty ? 0 : onlyMeKm2 / _total;
  double get shared => isEmpty ? 0 : sharedKm2 / _total;
  double get onlyFriend => isEmpty ? 0 : onlyFriendKm2 / _total;
}

/// A place both can explore, with the discovered part of it for each.
@immutable
class PlaceComparison {
  const PlaceComparison({
    required this.name,
    required this.myShare,
    required this.friendShare,
  });

  final String name;

  /// 0 to 1.
  final double myShare;
  final double friendShare;
}

@immutable
class FriendComparison {
  const FriendComparison({
    this.split,
    this.discoveredThisWeek = const Duel(),
    this.countries = const Duel(),
    this.quests = const Duel(),
    this.places = const [],
  });

  /// Null while unknown.
  final AreaSplit? split;
  final Duel discoveredThisWeek;
  final Duel countries;
  final Duel quests;
  final List<PlaceComparison> places;
}

// TODO(data): the split of the discovered area, both countries, the friend's
// completed quests and the places to compare, from the bitmap fogs and the
// backend.
final friendComparisonProvider = Provider.family<FriendComparison, String>((
  ref,
  username,
) {
  final mine = ref.watch(myActivityProvider);
  final theirs = ref.watch(friendActivityProvider(username));
  return FriendComparison(
    discoveredThisWeek: Duel(me: mine.weeklyKm2, friend: theirs.weeklyKm2),
    quests: Duel(me: ref.watch(questLevelProvider).completed),
  );
});
