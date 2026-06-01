package sniezynki.agh.globetrottr.profile.dto;

import lombok.Builder;

@Builder
public record UserProfileResponse(
        String username,
        String avatarUrl,
        String bio,
        int totalPoints
) {
}
