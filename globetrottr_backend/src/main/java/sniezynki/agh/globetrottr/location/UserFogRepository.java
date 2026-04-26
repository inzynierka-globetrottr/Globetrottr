package sniezynki.agh.globetrottr.location;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface UserFogRepository extends JpaRepository<UserFog, Long> {
    Optional<UserFog> findByUser_UserId(UUID userId);
}