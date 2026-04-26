package sniezynki.agh.globetrottr.sync.dto;

import sniezynki.agh.globetrottr.location.dto.PointDto;

import java.util.List;

public record SyncRequest(
        List<PointDto> points
) {
}
