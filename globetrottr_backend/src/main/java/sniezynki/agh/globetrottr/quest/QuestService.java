package sniezynki.agh.globetrottr.quest;

import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Geometry;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.location.UserFog;
import sniezynki.agh.globetrottr.location.UserFogRepository;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class QuestService {

    private final UserQuestRepository userQuestRepository;
    private final QuestRepository questRepository;
    private final UserRepository userRepository;
    private final UserFogRepository userFogRepository;

    public List<QuestResponseDto> getAllQuestsForSidebar(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        UUID userId = user.getUserId();

        UserFog userFog = userFogRepository.findByUser_UserId(userId).orElse(null);
        List<Quest> allGlobalQuests = questRepository.findAll();
        List<UserQuest> userQuests = userQuestRepository.findByUser_UserId(userId);

        Map<Long, UserQuest> userProgressMap = userQuests.stream()
                .collect(Collectors.toMap(uq -> uq.getQuest().getId(), uq -> uq));

        return allGlobalQuests.stream().map(quest -> {
            UserQuest uq = userProgressMap.get(quest.getId());
            boolean isStarted = (uq != null);
            boolean isCompleted = isStarted && uq.isCompleted();
            double progress = isStarted ? (isCompleted ? 1.0 : calculateProgress(userFog, quest)) : 0.0;

            return new QuestResponseDto(
                    quest.getId(),
                    quest.getTitle(),
                    quest.getType(),
                    quest.getRewardPoints(),
                    progress,
                    isStarted,
                    isCompleted
            );
        }).toList();
    }

    public double calculateProgress(UserFog userFog, Quest quest) {
        if (userFog == null || userFog.getFogArea() == null || quest.getQuestGeometry() == null) {
            return 0.0;
        }

        Geometry fogArea = userFog.getFogArea();
        Geometry target = quest.getQuestGeometry();

        return switch (quest.getType()) {
            case VISIT_POINTS -> calculateVisitPointsProgress(fogArea, target);
            case FOLLOW_ROUTE -> calculateFollowRouteProgress(fogArea, target);
        };
    }

    private double calculateVisitPointsProgress(Geometry fogArea, Geometry targetPoints) {
        int totalPoints = targetPoints.getNumGeometries();
        if (totalPoints == 0) return 0.0;

        int visitedPoints = 0;

        // Tolerence of aprox. 5 meters in degrees (for SRID 4326)
        final double toleranceInDegrees = 0.000045;

        for (int i = 0; i < totalPoints; i++) {
            Geometry questPoint = targetPoints.getGeometryN(i);
            if (fogArea.isWithinDistance(questPoint, toleranceInDegrees)) {
                visitedPoints++;
            }
        }
        return (double) visitedPoints / totalPoints;
    }


    private double calculateFollowRouteProgress(Geometry fogArea, Geometry targetRoute) {
        Geometry coveredRoute = targetRoute.intersection(fogArea);

        double totalLength = targetRoute.getLength();
        if (totalLength == 0) return 0.0;

        double coveredLength = coveredRoute.getLength();

        double progress = coveredLength / totalLength;
        return Math.min(progress, 1.0);
    }

    @Transactional
    public void checkAndCompleteQuests(User user, UserFog userFog) {
        List<UserQuest> activeQuests = userQuestRepository.findByUser_UserIdAndIsCompletedFalse(user.getUserId());
        double progressTolerance = 0.98;
        if (activeQuests.isEmpty()) {
            return;
        }

        boolean userPointsUpdated = false;

        for (UserQuest userQuest : activeQuests) {
            Quest quest = userQuest.getQuest();

            double progress = calculateProgress(userFog, quest);

            /*
            * Geolocation tolerance: 0.98 instead of 1.0 (i.e., 98%)
            * GPS or floating-point operations in PostGIS might truncate tiny fractions.
            * It's better to mark the quest as completed when the player has 98-99% coverage.
            * */

            if (progress >= progressTolerance) {

                userQuest.setCompleted(true);
                userQuest.setCompletedAt(LocalDateTime.now());
                userQuestRepository.save(userQuest);

                int currentPoints = user.getTotalPoints() != null ? user.getTotalPoints() : 0;
                int reward = quest.getRewardPoints() != null ? quest.getRewardPoints() : 0;
                user.setTotalPoints(currentPoints + reward);

                userPointsUpdated = true;
            }
        }

        if (userPointsUpdated) {
            userRepository.save(user);
        }
    }

    @Transactional
    public void startQuest(String username, Long questId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        UUID userId = user.getUserId();

        boolean alreadyStarted = userQuestRepository.findByUser_UserId(userId)
                .stream().anyMatch(uq -> uq.getQuest().getId().equals(questId));

        if (alreadyStarted) return;

        Quest quest = questRepository.findById(questId)
                .orElseThrow(() -> new RuntimeException("Quest not found"));

        UserQuest newUserQuest = UserQuest.builder()
                .user(user)
                .quest(quest)
                .isCompleted(false)
                .build();

        userQuestRepository.save(newUserQuest);
    }
}