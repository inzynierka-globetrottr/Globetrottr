package sniezynki.agh.globetrottr.statistics.dto;

public record RegionStatisticSyncDto(
        Long regionId,
        String regionName,
        String regionCode,
        Double discoveredAreaKm2,
        Double discoveryPercentage) {}
