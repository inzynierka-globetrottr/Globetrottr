package sniezynki.agh.globetrottr.statistics.dto;

import sniezynki.agh.globetrottr.region.RegionType;

public record RegionStatisticDto(
        String name,
        RegionType type,
        Double discoveredAreaKm2,
        Double discoveryPercentage
) {
}
