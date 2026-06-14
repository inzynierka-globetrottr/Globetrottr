package sniezynki.agh.globetrottr.quest;

public record QuestResponseDto(
        Long id,
        String title,
        QuestType type,
        Integer rewardPoints,
        Double progress,
        boolean isStarted,
        boolean isCompleted
) {}
