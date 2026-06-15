package sniezynki.agh.globetrottr.region;

import org.locationtech.jts.geom.Geometry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RegionRepository extends JpaRepository<Region, Long> {

    boolean existsByName(String name);

    @Query(value = "SELECT r.* FROM regions r WHERE ST_Intersects(r.geom, :fogGeom)", nativeQuery = true)
    List<Region> findRegionsIntersectingWithFog(@Param("fogGeom") Geometry fogGeom);
}