package sniezynki.agh.globetrottr.user.dto;

import jakarta.validation.constraints.NotBlank;

public record GoogleAuthRequest (
  @NotBlank(message = "Token cant be blank")
  String token
)
{ }
