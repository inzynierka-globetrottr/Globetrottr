package sniezynki.agh.globetrottr.statistics;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserStatisticsRepository extends JpaRepository<UserStatistics, Long> {

    Optional<UserStatistics> findByUser_Username(String username);

}