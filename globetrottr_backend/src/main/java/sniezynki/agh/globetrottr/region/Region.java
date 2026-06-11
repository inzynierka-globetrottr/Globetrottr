package sniezynki.agh.globetrottr.region;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.MultiPolygon;

@Entity
@Table(name = "regions")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Region {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RegionType type;

    @Column(columnDefinition = "geometry(MultiPolygon, 4326)", nullable = false)
    private MultiPolygon geom;

    @Column(name = "total_area_km2")
    private Double totalAreaKm2;
}