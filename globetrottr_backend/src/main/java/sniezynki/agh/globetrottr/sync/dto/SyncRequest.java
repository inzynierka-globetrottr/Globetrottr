package sniezynki.agh.globetrottr.sync.dto;

import java.util.List;
import sniezynki.agh.globetrottr.location.dto.PointDto;
import sniezynki.agh.globetrottr.statistics.dto.StatisticsSyncDto;

public record SyncRequest(List<PointDto> points, StatisticsSyncDto statistics) {
    public SyncRequest(List<PointDto> points) {
        this(points, null);
    }
}
