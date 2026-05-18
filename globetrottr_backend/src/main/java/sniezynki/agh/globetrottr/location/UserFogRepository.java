package sniezynki.agh.globetrottr.location;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserFogRepository extends JpaRepository<UserFog, Long> {
    Optional<UserFog> findByUser_UserId(UUID userId);

    @Query(value = "SELECT ST_AsGeoJSON(fog_area) FROM user_fog uf JOIN users u ON uf.user_id = u.user_id WHERE u.username = :username", nativeQuery = true)
    Optional<String> findFogGeoJsonByUsername(@Param("username") String username);
}