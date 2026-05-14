package sniezynki.agh.globetrottr.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ResendCodeRequest(
        @Email @Size(min = 6)
        @NotNull
        String email
) {
}
