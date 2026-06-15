package sniezynki.agh.globetrottr.user.dto;

import lombok.Builder;
import java.util.UUID;

@Builder
public record UserProfileResponse(
        UUID userId,
        String username,
        String email,
        Integer totalPoints
) {}