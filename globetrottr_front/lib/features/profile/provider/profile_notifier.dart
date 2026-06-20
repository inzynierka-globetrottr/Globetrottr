import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/features/profile/data/user_profile_response.dart';
import 'package:globetrottr_front/features/profile/provider/profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  late final ProfileService _service;

  @override
  ProfileState build() {
    _service = ProfileService();
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _service.getMyProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network error. Failed to load profile.',
      );
    }
  }

  Future<void> updateBio(String bio) async {
    if (state.profile == null) return;

    state = state.copyWith(isUpdatingBio: true);

    try {
      await _service.updateBio(bio);
      final current = state.profile!;
      state = state.copyWith(
        isUpdatingBio: false,
        profile: UserProfileResponse(
          username: current.username,
          avatarUrl: current.avatarUrl,
          bio: bio,
          totalPoints: current.totalPoints,
        ),
      );
    } on AppException catch (e) {
      state = state.copyWith(isUpdatingBio: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isUpdatingBio: false,
        errorMessage: 'Failed to update bio.',
      );
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    if (state.profile == null) return;
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final newUrl = await _service.uploadAvatar(filePath);
      final current = state.profile!;
      state = state.copyWith(
        isUploadingAvatar: false,
        profile: UserProfileResponse(
          username: current.username,
          avatarUrl: newUrl,
          bio: current.bio,
          totalPoints: current.totalPoints,
        ),
      );
    } on AppException catch (e) {
      state = state.copyWith(isUploadingAvatar: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isUploadingAvatar: false,
        errorMessage: 'Failed to upload avatar.',
      );
    }
  }
}
