package sniezynki.agh.globetrottr.statistics.dto;

import java.util.List;

public record StatisticsSyncDto(
        Double totalDiscoveredKm2,
        Integer visitedCountriesCount,
        Integer currentStreak,
        Integer appStreak,
        List<RegionStatisticSyncDto> regions) {}
