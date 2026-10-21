class UserProfileResponse {
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int totalPoints;

  const UserProfileResponse({
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.totalPoints,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      totalPoints: json['totalPoints'] as int,
    );
  }

  static const _sentinel = Object();

  UserProfileResponse copyWith({
    String? username,
    Object? avatarUrl = _sentinel,
    Object? bio = _sentinel,
    int? totalPoints,
  }) {
    return UserProfileResponse(
      username: username ?? this.username,
      avatarUrl: avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
      bio: bio == _sentinel ? this.bio : bio as String?,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}
