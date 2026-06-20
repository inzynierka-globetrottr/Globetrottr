import 'package:globetrottr_front/features/profile/data/user_profile_response.dart';

class ProfileState {
  final UserProfileResponse? profile;
  final bool isLoading;
  final bool isUpdatingBio;
  final bool isUploadingAvatar;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdatingBio = false,
    this.isUploadingAvatar = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    UserProfileResponse? profile,
    bool? isLoading,
    bool? isUpdatingBio,
    bool? isUploadingAvatar,
    String? errorMessage,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isUpdatingBio: isUpdatingBio ?? this.isUpdatingBio,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
