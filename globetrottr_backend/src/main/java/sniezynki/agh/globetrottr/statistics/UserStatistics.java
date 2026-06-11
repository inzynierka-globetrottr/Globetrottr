package sniezynki.agh.globetrottr.statistics;

import jakarta.persistence.*;
import lombok.*;
import sniezynki.agh.globetrottr.user.User;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_statistics")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserStatistics {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", unique = true, nullable = false)
    private User user;

    private Double totalDiscoveredKm2;
    private Integer visitedCountriesCount;
    private Integer completedQuestsCount;
    private Integer currentStreak;

    @Column(name = "last_activity_date")
    private LocalDate lastActivityDate;

    private LocalDateTime lastUpdated;

    @PreUpdate
    @PrePersist
    public void updateTimeStamps() {
        lastUpdated = LocalDateTime.now();
    }
}