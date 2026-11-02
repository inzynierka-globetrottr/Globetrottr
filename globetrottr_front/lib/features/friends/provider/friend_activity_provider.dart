import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';
import 'package:globetrottr_front/features/friends/provider/weekly_ranking.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';

/// Discovery numbers of a person that the backend does not provide yet.
class FriendActivity {
  const FriendActivity({this.weeklyKm2, this.totalKm2, this.level});

  final double? weeklyKm2;
  final double? totalKm2;
  final int? level;
}

// TODO(data): weekly and total km² from the bitmap fog statistics of the
// friend, the level from quests.
final friendActivityProvider = Provider.family<FriendActivity, String>(
  (ref, username) => const FriendActivity(),
);

// TODO(data): the user's own km² this week from the bitmap fog.
final myActivityProvider = Provider<FriendActivity>(
  (ref) => const FriendActivity(),
);

// TODO(data): who the inviting user is, e.g. mutual friends or the area they
// explore.
final inviteContextProvider = Provider.family<String?, String>(
  (ref, username) => null,
);

/// The "this week" strip: the user and every friend with discovered area.
final weeklyRankingProvider = Provider<List<WeeklyEntry>>((ref) {
  final friends = ref.watch(friendsProvider.select((s) => s.friends));
  final profile = ref.watch(profileProvider.select((s) => s.profile));
  return weeklyRanking(
    me: WeeklyEntry(
      username: profile?.username ?? '',
      weeklyKm2: ref.watch(myActivityProvider).weeklyKm2,
      avatarUrl: profile?.avatarUrl,
      isMe: true,
    ),
    friends: [
      for (final friend in friends)
        WeeklyEntry(
          username: friend.username,
          weeklyKm2: ref
              .watch(friendActivityProvider(friend.username))
              .weeklyKm2,
          avatarUrl: friend.avatarUrl,
        ),
    ],
  );
});
