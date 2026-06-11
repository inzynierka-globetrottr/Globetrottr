package sniezynki.agh.globetrottr.statistics;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import sniezynki.agh.globetrottr.region.RegionType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRegionStatisticsRepository extends JpaRepository<UserRegionStatistics, Long> {

    Optional<UserRegionStatistics> findByUser_UserIdAndRegion_Id(UUID userId, Long regionId);

    List<UserRegionStatistics> findByUser_UserIdOrderByDiscoveryPercentageDesc(UUID userId);

    @Query(value = """
        SELECT ST_Area(ST_Intersection(ST_Union(f.fog_area), r.geom)::geography) / 1000000.0
        FROM user_fog f
        JOIN regions r ON r.id = :regionId
        WHERE f.user_id = :userId
        GROUP BY r.id
    """, nativeQuery = true)
    Double calculateIntersectionAreaKm2(@Param("userId") UUID userId, @Param("regionId") Long regionId);

    @Query(value = "SELECT ST_Area(fog_area::geography) / 1000000.0 FROM user_fog WHERE user_id = :userId", nativeQuery = true)
    Optional<Double> findTotalDiscoveredAreaKm2(@Param("userId") UUID userId);

    @Query("SELECT COUNT(urs) FROM UserRegionStatistics urs WHERE urs.user.userId = :userId AND urs.region.type = :regionType AND urs.discoveredAreaKm2 > 0")
    Integer countVisitedRegionsByType(@Param("userId") UUID userId, @Param("regionType") RegionType regionType);
}