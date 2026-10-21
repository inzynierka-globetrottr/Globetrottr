package sniezynki.agh.globetrottr.profile.dto;

import java.util.List;
import lombok.Builder;
import sniezynki.agh.globetrottr.statistics.dto.RegionStatisticDto;

@Builder
public record UserProfileResponse(
        // User profile
        String username,
        String avatarUrl,
        String bio,
        int totalPoints,

        // Global statistics
        Double totalDiscoveredKm2,
        int visitedCountriesCount,
        int completedQuestsCount,
        int currentStreak,

        // User regions
        List<RegionStatisticDto> regions) {}
