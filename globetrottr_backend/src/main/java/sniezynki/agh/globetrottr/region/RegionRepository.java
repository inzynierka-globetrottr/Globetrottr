package sniezynki.agh.globetrottr.region;

import java.util.List;
import java.util.Optional;
import org.locationtech.jts.geom.Geometry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RegionRepository extends JpaRepository<Region, Long> {

    boolean existsByName(String name);

    Optional<Region> findByNameIgnoreCase(String name);

    Optional<Region> findByCodeIgnoreCase(String code);

    Optional<Region> findByNameIgnoreCaseAndCodeIgnoreCase(String name, String code);

    @Query(
            value = "SELECT r.* FROM regions r WHERE ST_Intersects(r.geom, :fogGeom)",
            nativeQuery = true)
    List<Region> findRegionsIntersectingWithFog(@Param("fogGeom") Geometry fogGeom);
}
