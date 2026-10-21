import 'package:globetrottr_front/features/friends/data/invite_status.dart';

class FriendshipResponse {
  final String username;
  final InviteStatus? status;
  final bool isIncomingRequest;
  final String? avatarUrl;

  const FriendshipResponse({
    required this.username,
    required this.status,
    required this.isIncomingRequest,
    this.avatarUrl,
  });

  factory FriendshipResponse.fromJson(Map<String, dynamic> json) {
    return FriendshipResponse(
      username: json['username'] as String,
      status: InviteStatus.fromString(json['status'] as String?),
      isIncomingRequest: json['isIncomingRequest'] as bool,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  FriendshipResponse copyWith({
    String? username,
    InviteStatus? status,
    bool? isIncomingRequest,
    String? avatarUrl,
  }) {
    return FriendshipResponse(
      username: username ?? this.username,
      status: status ?? this.status,
      isIncomingRequest: isIncomingRequest ?? this.isIncomingRequest,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
