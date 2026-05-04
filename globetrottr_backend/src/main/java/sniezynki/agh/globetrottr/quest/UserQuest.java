package sniezynki.agh.globetrottr.quest;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import sniezynki.agh.globetrottr.user.User;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_quests")
@Getter
@Setter
public class UserQuest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "user_id")
    private User user;

    @ManyToOne
    @JoinColumn(name = "quest_id")
    private Quest quest;

    private boolean completed = false;

    private LocalDateTime completedAt;
}