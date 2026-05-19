package sniezynki.agh.globetrottr.quest;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.locationtech.jts.geom.Geometry;

@Entity
@Table(name = "quests")
@Getter
@Setter
public class Quest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    @Enumerated(EnumType.STRING)
    private QuestType type;

    @Column(columnDefinition = "geometry(Geometry, 4326)")
    private Geometry questGeometry;

    private Integer rewardPoints;
}