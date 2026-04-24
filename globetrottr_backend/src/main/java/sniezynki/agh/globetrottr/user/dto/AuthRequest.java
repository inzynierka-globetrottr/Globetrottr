package sniezynki.agh.globetrottr.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Builder;

@Builder
public record AuthRequest(
        @NotBlank
        String login,

        @NotBlank
        String password
) {}