package sniezynki.agh.globetrottr.sync.dto;

import java.util.List;
import sniezynki.agh.globetrottr.location.dto.PointDto;

public record SyncRequest(List<PointDto> points) {}
