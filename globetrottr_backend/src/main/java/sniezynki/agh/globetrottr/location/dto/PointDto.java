package sniezynki.agh.globetrottr.location.dto;

import lombok.Builder;

public record PointDto(
    double latitude,
    double longitude,
    long timestamp
) {
}
