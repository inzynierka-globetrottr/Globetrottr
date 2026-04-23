package sniezynki.agh.globetrottr.user.dto;

import lombok.Builder;

@Builder
public record RegisterRequest(
        String username,
        String email,
        String password
) {}