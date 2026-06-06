import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friends_notifier.dart';
import 'package:globetrottr_front/features/friends/provider/friends_state.dart';

final friendsProvider = NotifierProvider<FriendsNotifier, FriendsState>(() {
  return FriendsNotifier();
});