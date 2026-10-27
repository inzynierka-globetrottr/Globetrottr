package sniezynki.agh.globetrottr.quest;

import java.util.Arrays;
import java.util.List;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;

final class QuestGeometryMapper {

    private QuestGeometryMapper() {}

    /**
     * Route quests are anchored at their first vertex so the map pin marks where the walk begins;
     * other quests use an interior point, which for a MULTIPOINT is always one of the targets.
     */
    static QuestCoordinateDto anchorOf(Quest quest) {
        Geometry geometry = quest.getQuestGeometry();
        if (geometry == null || geometry.isEmpty()) {
            return null;
        }
        Coordinate anchor =
                quest.getType() == QuestType.FOLLOW_ROUTE
                        ? geometry.getCoordinates()[0]
                        : geometry.getInteriorPoint().getCoordinate();
        return toDto(anchor);
    }

    static List<QuestCoordinateDto> waypointsOf(Quest quest) {
        Geometry geometry = quest.getQuestGeometry();
        if (geometry == null) {
            return List.of();
        }
        return Arrays.stream(geometry.getCoordinates()).map(QuestGeometryMapper::toDto).toList();
    }

    private static QuestCoordinateDto toDto(Coordinate coordinate) {
        return new QuestCoordinateDto(coordinate.getY(), coordinate.getX());
    }
}
