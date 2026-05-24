package sniezynki.agh.globetrottr.quest;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.io.ParseException;
import org.locationtech.jts.io.WKTReader;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import sniezynki.agh.globetrottr.location.UserFog;
import sniezynki.agh.globetrottr.location.UserFogRepository;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.data.Offset.offset;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class QuestServiceTest {

    @Mock
    private UserQuestRepository userQuestRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserFogRepository userFogRepository;

    @InjectMocks
    private QuestService questService;

    private UUID userId;
    private User user;
    private UserFog userFog;
    private final WKTReader wktReader = new WKTReader();

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = new User();
        user.setUserId(userId);
        user.setTotalPoints(100);

        userFog = new UserFog();
        userFog.setUser(user);
    }

    @Test
    void shouldMapAndCalculateProgressForFollowRouteQuest() {
        Geometry userDiscoverArea = createGeometry("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))");
        userFog.setFogArea(userDiscoverArea);

        // Route covers 50% of the fog
        Geometry routeQuestGeom = createGeometry("LINESTRING(5 5, 15 5)");
        Quest quest = createQuest(1L, "Route Quest", QuestType.FOLLOW_ROUTE, 50, routeQuestGeom);
        UserQuest userQuest = createUserQuest(quest, false);

        when(userFogRepository.findByUser_UserId(userId)).thenReturn(Optional.of(userFog));
        when(userQuestRepository.findByUser_UserId(userId)).thenReturn(List.of(userQuest));

        List<QuestResponseDto> result = questService.getAllQuestsForUser(userId);

        assertThat(result).hasSize(1);

        QuestResponseDto response = result.getFirst();
        assertThat(response.title()).isEqualTo("Route Quest");
        assertThat(response.type()).isEqualTo(QuestType.FOLLOW_ROUTE);
        assertThat(response.progress()).isCloseTo(0.5, offset(0.001));
        assertThat(response.isCompleted()).isFalse();
    }

    @Test
    void shouldMapAndCalculateProgressForVisitPointsQuest() {
        Geometry userDiscoverArea = createGeometry("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))");
        userFog.setFogArea(userDiscoverArea);

        // 2 points inside the fog, 1 outside (progress 2/3)
        Geometry pointsGeom = createGeometry("MULTIPOINT(5 5, 2 2, 15 15)");
        Quest quest = createQuest(2L, "Points Quest", QuestType.VISIT_POINTS, 20, pointsGeom);
        UserQuest userQuest = createUserQuest(quest, false);

        when(userFogRepository.findByUser_UserId(userId)).thenReturn(Optional.of(userFog));
        when(userQuestRepository.findByUser_UserId(userId)).thenReturn(List.of(userQuest));

        List<QuestResponseDto> result = questService.getAllQuestsForUser(userId);

        assertThat(result).hasSize(1);

        QuestResponseDto response = result.getFirst();
        assertThat(response.title()).isEqualTo("Points Quest");
        assertThat(response.type()).isEqualTo(QuestType.VISIT_POINTS);
        assertThat(response.progress()).isCloseTo(0.666, offset(0.01));
        assertThat(response.isCompleted()).isFalse();
    }

    @Test
    void shouldReturnFullProgressForAlreadyCompletedQuestRegardlessOfFog() {
        Geometry userDiscoverArea = createGeometry("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))");
        userFog.setFogArea(userDiscoverArea);

        // Setting a valid geometry but placing it 100% OUTSIDE the fog
        Geometry outsideGeom = createGeometry("POINT(100 100)");
        Quest quest = createQuest(3L, "Completed Quest", QuestType.VISIT_POINTS, 50, outsideGeom);

        // But marking the quest as COMPLETED
        UserQuest userQuest = createUserQuest(quest, true);

        when(userFogRepository.findByUser_UserId(userId)).thenReturn(Optional.of(userFog));
        when(userQuestRepository.findByUser_UserId(userId)).thenReturn(List.of(userQuest));

        List<QuestResponseDto> result = questService.getAllQuestsForUser(userId);

        assertThat(result).hasSize(1);

        QuestResponseDto response = result.getFirst();
        assertThat(response.title()).isEqualTo("Completed Quest");
        // Even if the geometry is outside the fog, we expect 1.0 because the quest status is isCompleted = true
        assertThat(response.progress()).isEqualTo(1.0);
        assertThat(response.isCompleted()).isTrue();
    }

    @Test
    void calculateProgress_ShouldReturnZeroWhenFogIsNull() {
        Quest quest = createQuest(1L, "Q", QuestType.VISIT_POINTS, 10, createGeometry("POINT(1 1)"));

        double progress = questService.calculateProgress(null, quest);

        assertThat(progress).isEqualTo(0.0);
    }

    @Test
    void calculateProgress_ShouldReturnZeroWhenQuestGeometryIsNull() {
        userFog.setFogArea(createGeometry("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))"));
        Quest quest = createQuest(1L, "Q", QuestType.FOLLOW_ROUTE, 10, null);

        double progress = questService.calculateProgress(userFog, quest);

        assertThat(progress).isEqualTo(0.0);
    }

    @Test
    void calculateProgress_VisitPoints_ShouldCalculateCorrectly() {
        userFog.setFogArea(createGeometry("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0))"));

        // Points:
        // (5 5) - inside the fog
        // (5 10.00001) - outside the polygon, but within tolerance (0.000045)
        // (15 15) - completely outside the fog
        Geometry targetPoints = createGeometry("MULTIPOINT(5 5, 5 10.00001, 15 15)");
        Quest quest = createQuest(1L, "Visit Quest", QuestType.VISIT_POINTS, 30, targetPoints);

        double progress = questService.calculateProgress(userFog, quest);

        // 2 out of 3 points completed
        assertThat(progress).isCloseTo(0.666, offset(0.001));
    }

    @Test
    void checkAndCompleteQuests_ShouldCompleteQuestAndAddPointsWhenProgressAboveTolerance() {
        userFog.setFogArea(createGeometry("POLYGON((0 0, 0 100, 100 100, 100 0, 0 0))"));

        // Route length is 100 units, of which 99 is in the fog (99% progress - threshold is 98%)
        Geometry questGeometry = createGeometry("LINESTRING(0 50, 100 50)");
        Quest quest = createQuest(1L, "Route", QuestType.FOLLOW_ROUTE, 50, questGeometry);
        UserQuest userQuest = createUserQuest(quest, false);

        when(userQuestRepository.findByUser_UserIdAndCompletedFalse(userId)).thenReturn(List.of(userQuest));

        questService.checkAndCompleteQuests(user, userFog);

        assertThat(userQuest.isCompleted()).isTrue();
        assertThat(userQuest.getCompletedAt()).isNotNull();
        assertThat(user.getTotalPoints()).isEqualTo(150);

        verify(userQuestRepository).save(userQuest);
        verify(userRepository).save(user);
    }

    @Test
    void checkAndCompleteQuests_ShouldNotCompleteQuestWhenProgressBelowTolerance() {
        userFog.setFogArea(createGeometry("POLYGON((0 0, 0 50, 50 50, 50 0, 0 0))"));

        // Route length is 100, only 50 covered by fog (50% progress)
        Geometry questGeometry = createGeometry("LINESTRING(0 25, 100 25)");
        Quest quest = createQuest(1L, "Route", QuestType.FOLLOW_ROUTE, 50, questGeometry);
        UserQuest userQuest = createUserQuest(quest, false);

        when(userQuestRepository.findByUser_UserIdAndCompletedFalse(userId)).thenReturn(List.of(userQuest));

        questService.checkAndCompleteQuests(user, userFog);

        assertThat(userQuest.isCompleted()).isFalse();
        assertThat(userQuest.getCompletedAt()).isNull();
        assertThat(user.getTotalPoints()).isEqualTo(100);

        verify(userQuestRepository, never()).save(any());
        verify(userRepository, never()).save(any());
    }

    private Geometry createGeometry(String wkt) {
        try {
            return wktReader.read(wkt);
        } catch (ParseException e) {
            throw new IllegalArgumentException("Invalid WKT format: " + wkt, e);
        }
    }

    private Quest createQuest(Long id, String title, QuestType type, int reward, Geometry geometry) {
        return Quest.builder()
                .id(id)
                .title(title)
                .type(type)
                .rewardPoints(reward)
                .questGeometry(geometry)
                .build();
    }

    private UserQuest createUserQuest(Quest quest, boolean isCompleted) {
        return UserQuest.builder()
                .quest(quest)
                .isCompleted(isCompleted)
                .build();
    }
}