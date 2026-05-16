package sniezynki.agh.globetrottr.friend.dto;

import jakarta.validation.constraints.NotBlank;

public record FriendshipRequest(
        @NotBlank String username
) {
}
