package sniezynki.agh.globetrottr.location;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.locationtech.jts.geom.Geometry;
import sniezynki.agh.globetrottr.user.User;

@Entity
@Table(name = "user_fog")
@Getter
@Setter
// TODO(fog): replace with fog_tiles(user_id, z, x, y, rev, flag, data) once clients
// upload bitmap tiles.
public class UserFog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", referencedColumnName = "user_id")
    private User user;

    @Column(columnDefinition = "geometry(Geometry, 4326)")
    private Geometry fogArea;
}
