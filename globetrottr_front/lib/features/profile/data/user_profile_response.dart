class UserProfileResponse {
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int totalPoints;

  const UserProfileResponse({
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.totalPoints
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      totalPoints: json['totalPoints'] as int
    );
  }
}