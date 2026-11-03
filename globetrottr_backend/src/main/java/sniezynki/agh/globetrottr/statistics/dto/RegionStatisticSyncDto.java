package sniezynki.agh.globetrottr.statistics.dto;

public record RegionStatisticSyncDto(
        Long regionId, Double discoveredAreaKm2, Double discoveryPercentage) {}
