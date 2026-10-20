import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/profile/provider/profile_notifier.dart';
import 'package:globetrottr_front/features/profile/provider/profile_state.dart';

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
