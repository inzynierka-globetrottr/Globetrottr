package sniezynki.agh.globetrottr.quest;

import java.util.Arrays;
import java.util.List;
import java.util.function.Predicate;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;

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

    static List<QuestWaypointDto> waypointsOf(Quest quest, Predicate<Point> isVisited) {
        Geometry geometry = quest.getQuestGeometry();
        if (geometry == null) {
            return List.of();
        }
        GeometryFactory factory = geometry.getFactory();
        return Arrays.stream(geometry.getCoordinates())
                .map(
                        coordinate ->
                                new QuestWaypointDto(
                                        coordinate.getY(),
                                        coordinate.getX(),
                                        isVisited.test(factory.createPoint(coordinate))))
                .toList();
    }

    private static QuestCoordinateDto toDto(Coordinate coordinate) {
        return new QuestCoordinateDto(coordinate.getY(), coordinate.getX());
    }
}
