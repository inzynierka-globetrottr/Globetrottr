package sniezynki.agh.globetrottr.quest;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserQuestRepository extends JpaRepository<UserQuest, Long> {

    List<UserQuest> findByUser_UserIdAndIsCompletedFalse(UUID userId);

    List<UserQuest> findByUser_UserId(UUID userId);
}
