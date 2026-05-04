package sniezynki.agh.globetrottr.quest;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface UserQuestRepository extends JpaRepository<UserQuest, Long> {

    List<UserQuest> findByUser_UserIdAndCompletedFalse(UUID userId);
    List<UserQuest> findByUser_Username(String username);
}