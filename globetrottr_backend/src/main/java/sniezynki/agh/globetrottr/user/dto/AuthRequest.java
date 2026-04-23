package sniezynki.agh.globetrottr.user.dto;

import lombok.Builder;

@Builder
public record AuthRequest(
        String login,
        String password
) {}