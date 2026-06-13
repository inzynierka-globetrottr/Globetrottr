package sniezynki.agh.globetrottr.profile.dto;

import jakarta.validation.constraints.Size;

public record UpdateBioRequest(
        @Size(max = 255, message = "Bio cannot exceed 255 characters")
        String bio
) {
}