import 'package:globetrottr_front/features/friends/data/invite_status.dart';

class FriendshipResponse {
  final String username;
  final InviteStatus? status;
  final bool isIncomingRequest;

  const FriendshipResponse({
    required this.username,
    required this.status,
    required this.isIncomingRequest,
  });

  factory FriendshipResponse.fromJson(Map<String, dynamic> json) {
    return FriendshipResponse(
      username: json['username'] as String,
      status: InviteStatus.fromString(json['status'] as String?),
      isIncomingRequest: json['isIncomingRequest'] as bool,
    );
  }
}