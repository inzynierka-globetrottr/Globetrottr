package sniezynki.agh.globetrottr.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record VerifyEmailRequest(
        @NotBlank
        @Email(message = "email should be valid")
        String email,

        @NotBlank
        @Size(min = 6, max = 6, message = "Code must be 6 digit")
        String code
) {
}
