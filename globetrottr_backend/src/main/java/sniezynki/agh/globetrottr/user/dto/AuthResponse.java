package sniezynki.agh.globetrottr.user.dto;

import lombok.Builder;

@Builder
public record AuthResponse(
        String token
) {}