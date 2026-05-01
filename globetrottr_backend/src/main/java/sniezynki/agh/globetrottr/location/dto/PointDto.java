package sniezynki.agh.globetrottr.location.dto;

import lombok.Builder;

public record PointDto(
    String sessionId,
    double latitude,
    double longitude,
    long timestamp
) {
}
