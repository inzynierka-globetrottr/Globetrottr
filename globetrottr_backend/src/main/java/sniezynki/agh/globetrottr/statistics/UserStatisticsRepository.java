package sniezynki.agh.globetrottr.statistics;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserStatisticsRepository extends JpaRepository<UserStatistics, Long> {

    Optional<UserStatistics> findByUser_Username(String username);
}
