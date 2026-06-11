package sniezynki.agh.globetrottr.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.location.UserFog;
import sniezynki.agh.globetrottr.location.UserFogRepository;
import sniezynki.agh.globetrottr.location.dto.PointDto;
import sniezynki.agh.globetrottr.quest.QuestService;
import sniezynki.agh.globetrottr.statistics.StatisticsSyncService;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class SyncService {

    private final UserFogRepository userFogRepository;
    private final UserRepository userRepository;
    private final QuestService  questService;
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    private final StatisticsSyncService statisticsSyncService;

    @Transactional
    public void processPoints(List<PointDto> points, String username) {
        if (points == null || points.isEmpty()) {
            log.warn("No points received");
            return;
        }

        User user = userRepository.findByUsername(username).orElseThrow();
        UserFog userFog = userFogRepository.findByUser_UserId(user.getUserId())
                .orElseGet(() -> {
                    UserFog newFog = new UserFog();
                    newFog.setUser(user);
                    return newFog;
                });

        Geometry currentFog = userFog.getFogArea();
        Geometry batchNewArea = null;

        double distance = 0.0002;

        Map<String, List<PointDto>> groupedPoints = points.stream()
                .collect(Collectors.groupingBy(PointDto::sessionId));


        for (Map.Entry<String, List<PointDto>> entry : groupedPoints.entrySet()) {
            List<PointDto> sessionPoints = entry.getValue();

            sessionPoints.sort(Comparator.comparingLong(PointDto::timestamp));

            Geometry newlyDiscoveredArea;

            if (sessionPoints.size() >= 2) {
                Coordinate[] coordinates = sessionPoints.stream()
                        .map(p -> new Coordinate(p.longitude(), p.latitude()))
                        .toArray(Coordinate[]::new);

                LineString walkedPath = geometryFactory.createLineString(coordinates);
                newlyDiscoveredArea = walkedPath.buffer(distance);
            } else {
                PointDto p = sessionPoints.getFirst();
                Point singlePoint = geometryFactory.createPoint(new Coordinate(p.longitude(), p.latitude()));
                newlyDiscoveredArea = singlePoint.buffer(distance);
        }

            if (currentFog == null) {
                currentFog = newlyDiscoveredArea;
            } else {
                currentFog = currentFog.union(newlyDiscoveredArea);
            }

            if (batchNewArea == null) {
                batchNewArea = newlyDiscoveredArea;
            } else {
                batchNewArea = batchNewArea.union(newlyDiscoveredArea);
            }
        }

        userFog.setFogArea(currentFog);
        userFogRepository.save(userFog);
        log.info("Updated fog for user: {}", username);
        questService.checkAndCompleteQuests(user, userFog);

        if (batchNewArea != null) {
            statisticsSyncService.recalculateStatsForNewFog(user, batchNewArea);
        }
    }
}