package sniezynki.agh.globetrottr.friend.dto;

import jakarta.validation.constraints.NotNull;
import sniezynki.agh.globetrottr.friend.InviteStatus;

public record FriendshipResponse(
        @NotNull String username,
        @NotNull InviteStatus  status
        ) {
}
