package sniezynki.agh.globetrottr.statistics;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import sniezynki.agh.globetrottr.region.Region;
import sniezynki.agh.globetrottr.region.RegionRepository;
import sniezynki.agh.globetrottr.region.RegionType;
import sniezynki.agh.globetrottr.statistics.dto.RegionStatisticSyncDto;
import sniezynki.agh.globetrottr.statistics.dto.StatisticsSyncDto;
import sniezynki.agh.globetrottr.user.User;

@ExtendWith(MockitoExtension.class)
class StatisticsSyncServiceTest {

    @Mock private RegionRepository regionRepository;
    @Mock private UserRegionStatisticsRepository userRegionStatRepository;
    @Mock private UserStatisticsRepository userStatisticsRepository;

    @InjectMocks private StatisticsSyncService statisticsSyncService;

    private User user;
    private Region region;

    @BeforeEach
    void setUp() {
        user = User.builder().userId(UUID.randomUUID()).username("tester").build();
        region =
                Region.builder()
                        .id(1L)
                        .name("Poland")
                        .type(RegionType.COUNTRY)
                        .totalAreaKm2(312696.0)
                        .build();
    }

    @Test
    void shouldUpdateScalarUserStatisticsAndRegionsFromSyncDto() {
        when(userStatisticsRepository.findByUser_Username("tester")).thenReturn(Optional.empty());
        when(regionRepository.findByNameIgnoreCase("Poland")).thenReturn(Optional.of(region));
        when(userRegionStatRepository.findByUser_UserIdAndRegion_Id(user.getUserId(), 1L))
                .thenReturn(Optional.empty());

        StatisticsSyncDto dto =
                new StatisticsSyncDto(
                        15.5,
                        2,
                        7,
                        10,
                        List.of(new RegionStatisticSyncDto(1L, "Poland", "PL", 15.5, 0.005)));

        statisticsSyncService.updateUserStatistics(user, dto);

        ArgumentCaptor<UserStatistics> statsCaptor = ArgumentCaptor.forClass(UserStatistics.class);
        verify(userStatisticsRepository).save(statsCaptor.capture());
        UserStatistics saved = statsCaptor.getValue();

        assertEquals(15.5, saved.getTotalDiscoveredKm2());
        assertEquals(2, saved.getVisitedCountriesCount());
        assertEquals(7, saved.getCurrentStreak());
        assertEquals(10, saved.getAppStreak());

        ArgumentCaptor<UserRegionStatistics> regionStatCaptor =
                ArgumentCaptor.forClass(UserRegionStatistics.class);
        verify(userRegionStatRepository).save(regionStatCaptor.capture());
        UserRegionStatistics savedRegionStat = regionStatCaptor.getValue();

        assertEquals(15.5, savedRegionStat.getDiscoveredAreaKm2());
        assertEquals(0.005, savedRegionStat.getDiscoveryPercentage());
        assertEquals(region, savedRegionStat.getRegion());
    }

    @Test
    void shouldDoNothingWhenSyncDtoIsNull() {
        statisticsSyncService.updateUserStatistics(user, null);

        verifyNoInteractions(userStatisticsRepository);
        verifyNoInteractions(userRegionStatRepository);
    }
}
