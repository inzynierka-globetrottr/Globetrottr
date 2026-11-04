import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friends_notifier.dart';
import 'package:globetrottr_front/features/friends/provider/friends_state.dart';

final friendsProvider = NotifierProvider<FriendsNotifier, FriendsState>(() {
  return FriendsNotifier();
});

/// The avatar of a friend on the list; null while unknown.
final friendAvatarUrlProvider = Provider.family<String?, String>(
  (ref, username) => ref.watch(
    friendsProvider.select(
      (state) => state.friends
          .where((friend) => friend.username == username)
          .firstOrNull
          ?.avatarUrl,
    ),
  ),
);
