package sniezynki.agh.globetrottr.statistics;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Geometry;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.region.Region;
import sniezynki.agh.globetrottr.region.RegionRepository;
import sniezynki.agh.globetrottr.region.RegionType;
import sniezynki.agh.globetrottr.user.User;

import java.time.LocalDate;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class StatisticsSyncService {

    private final RegionRepository regionRepository;
    private final UserRegionStatisticsRepository userRegionStatRepository;
    private final UserStatisticsRepository userStatisticsRepository;

    @Transactional
    public void recalculateStatsForNewFog(User user, Geometry newFogGeom) {
        List<Region> affectedRegions = regionRepository.findRegionsIntersectingWithFog(newFogGeom);

        for (Region region : affectedRegions) {
            Double discoveredArea = userRegionStatRepository.calculateIntersectionAreaKm2(user.getUserId(), region.getId());

            if (discoveredArea == null) {
                discoveredArea = 0.0;
            }

            double percentage = (discoveredArea / region.getTotalAreaKm2()) * 100.0;
            percentage = Math.min(percentage, 100.0);

            UserRegionStatistics stat = userRegionStatRepository.findByUser_UserIdAndRegion_Id(user.getUserId(), region.getId())
                    .orElse(UserRegionStatistics.builder()
                            .user(user)
                            .region(region)
                            .build());

            stat.setDiscoveredAreaKm2(discoveredArea);
            stat.setDiscoveryPercentage(percentage);

            userRegionStatRepository.save(stat);
        }

        updateGlobalStatistics(user);
    }

    private void updateGlobalStatistics(User user) {
        Double totalArea = userRegionStatRepository.findTotalDiscoveredAreaKm2(user.getUserId()).orElse(0.0);

        Integer countriesCount = userRegionStatRepository.countVisitedRegionsByType(user.getUserId(), RegionType.COUNTRY);
        if (countriesCount == null) {
            countriesCount = 0;
        }

        UserStatistics globalStats = userStatisticsRepository.findByUser_Username(user.getUsername())
                .orElse(UserStatistics.builder()
                        .user(user)
                        .completedQuestsCount(0)
                        .currentStreak(0)
                        .build());

        globalStats.setTotalDiscoveredKm2(totalArea);
        globalStats.setVisitedCountriesCount(countriesCount);

        updateStreakLogic(globalStats);

        userStatisticsRepository.save(globalStats);
    }

    private void updateStreakLogic(UserStatistics stats) {
        LocalDate today = LocalDate.now();
        LocalDate lastActivity = stats.getLastActivityDate();

        if (lastActivity == null) {
            stats.setCurrentStreak(1);
            stats.setLastActivityDate(today);
        } else if (lastActivity.equals(today.minusDays(1))) {
            stats.setCurrentStreak(stats.getCurrentStreak() + 1);
            stats.setLastActivityDate(today);
        } else if (lastActivity.isBefore(today.minusDays(1))) {
            stats.setCurrentStreak(1);
            stats.setLastActivityDate(today);
        }
    }
}