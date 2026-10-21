package sniezynki.agh.globetrottr.user.dto;

import java.util.UUID;
import lombok.Builder;

@Builder
public record UserProfileResponse(
        UUID userId, String username, String email, Integer totalPoints) {}
