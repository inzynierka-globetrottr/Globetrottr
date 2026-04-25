package sniezynki.agh.globetrottr.sync;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import sniezynki.agh.globetrottr.location.dto.PointDto;
import sniezynki.agh.globetrottr.sync.dto.SyncRequest;

import java.util.List;

@Service
@Slf4j
public class SyncService {

    public void processPoints(List<PointDto> points) {
        log.info("Recived {} points to sync", points.size());

        for  (PointDto point : points) {
            log.info("Point: Lat: {}, Lng: {}, Time: {}",
                    point.latitude(), point.longitude(), point.timestamp());
        }
    }
}
