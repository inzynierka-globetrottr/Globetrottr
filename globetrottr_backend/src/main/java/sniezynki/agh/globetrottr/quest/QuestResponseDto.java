package sniezynki.agh.globetrottr.quest;

import java.util.List;

public record QuestResponseDto(
        Long id,
        String title,
        String description,
        QuestType type,
        Integer rewardPoints,
        Double progress,
        boolean isStarted,
        boolean isCompleted,
        QuestCoordinateDto location,
        List<QuestCoordinateDto> waypoints) {}
