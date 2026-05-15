package sniezynki.agh.globetrottr.friend.dto;

import jakarta.validation.constraints.NotNull;

public record FriendshipRequest(
        @NotNull String username
) {
}
