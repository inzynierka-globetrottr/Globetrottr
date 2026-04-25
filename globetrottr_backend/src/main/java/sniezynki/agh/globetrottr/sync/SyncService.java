package sniezynki.agh.globetrottr.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.location.UserFog;
import sniezynki.agh.globetrottr.location.UserFogRepository;
import sniezynki.agh.globetrottr.location.dto.PointDto;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class SyncService {

    private final UserFogRepository userFogRepository;
    private final UserRepository userRepository;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public void processPoints(List<PointDto> points, String username) {
        if (points == null || points.size() < 2) {
            log.warn("Not enough points to create polygon");
            return;
        }

        Coordinate[] coordinates = points.stream()
                .map(p -> new Coordinate(p.longitude(), p.latitude()))
                .toArray(Coordinate[]::new);

        LineString walkedPath = geometryFactory.createLineString(coordinates);

        double distance = 0.0002;
        Geometry newlyDiscoveredArea = walkedPath.buffer(distance);

        User user = userRepository.findByUsername(username).orElseThrow();
        UserFog userFog = userFogRepository.findByUser_UserId(user.getUserId())
                .orElseGet(() -> {
                    UserFog newFog = new UserFog();
                    newFog.setUser(user);
                    return newFog;
                });

        if (userFog.getFogArea() == null) {
            userFog.setFogArea(newlyDiscoveredArea);
        } else {
            Geometry combinedFog = userFog.getFogArea().union(newlyDiscoveredArea);
            userFog.setFogArea(combinedFog);
        }

        userFogRepository.save(userFog);
        log.info("Updated fog for user: {}", username);
    }
}