package sniezynki.agh.globetrottr.statistics;

import jakarta.persistence.*;
import lombok.*;
import sniezynki.agh.globetrottr.region.Region;
import sniezynki.agh.globetrottr.user.User;

@Entity
@Table(name = "user_region_statistics",
        uniqueConstraints = {@UniqueConstraint(
                name = "uc_user_region_statistics_user_id_region_id",
                columnNames = {"user_id", "region_id"})})
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class UserRegionStatistics {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id", nullable = false)
    private Region region;

    @Column(name = "discovered_area_km2")
    private Double discoveredAreaKm2;

    @Column(name = "discovery_percentage")
    private Double discoveryPercentage;
}