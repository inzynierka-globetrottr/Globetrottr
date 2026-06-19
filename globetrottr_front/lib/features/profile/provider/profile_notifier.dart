import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/features/profile/data/profile_service.dart';
import 'package:globetrottr_front/features/profile/provider/profile_state.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  late ProfileService _service;

  @override
  ProfileState build() {
    _service = ref.read(profileServiceProvider);
    return const ProfileState();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _service.getMyProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      print('Unexpected error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Failed to load profile.',
      );
    }
  }

  Future<void> updateBio(String bio) async {
    if (state.profile == null) return;

    state = state.copyWith(isUpdatingBio: true);

    try {
      await _service.updateBio(bio);
      state = state.copyWith(
        isUpdatingBio: false,
        profile: state.profile!.copyWith(bio: bio),
      );
    } on AppException catch (e) {
      state = state.copyWith(isUpdatingBio: false, errorMessage: e.message);
    } catch (e) {
      print('Unexpected error updating bio: $e');
      state = state.copyWith(isUpdatingBio: false, errorMessage: 'Failed to update bio.');
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    if (state.profile == null) return;
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final newUrl = await _service.uploadAvatar(filePath);
      state = state.copyWith(
        isUploadingAvatar: false,
        profile: state.profile!.copyWith(avatarUrl: newUrl),
      );
    } on AppException catch (e) {
      state = state.copyWith(isUploadingAvatar: false, errorMessage: e.message);
    } catch (e) {
      print('Unexpected error uploading avatar: $e');
      state = state.copyWith(isUpdatingBio: false, errorMessage: 'Failed to upload avatar.');
    }
  }
}
