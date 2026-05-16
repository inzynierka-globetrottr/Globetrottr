package sniezynki.agh.globetrottr.friend.dto;

import sniezynki.agh.globetrottr.friend.InviteStatus;

public record FriendshipResponse(
        String username,
        InviteStatus  status,
        Boolean isIncomingRequest
        ) {
}
