import 'package:flutter/material.dart';

/// Colours of the base map. Kept apart from `AppPalette` because the map
/// needs many shades of its own; a dark mode brings its own map palette.
///
/// Nothing on the map is saturated, so the accent of the player and the gold
/// of quests stay the strongest colours on the screen.
@immutable
class AppMapPalette extends ThemeExtension<AppMapPalette> {
  const AppMapPalette({
    required this.land,
    required this.landuse,
    required this.park,
    required this.wood,
    required this.grass,
    required this.water,
    required this.building,
    required this.buildingOutline,
    required this.road,
    required this.roadCasing,
    required this.majorRoad,
    required this.majorRoadCasing,
    required this.motorway,
    required this.motorwayCasing,
    required this.path,
    required this.rail,
    required this.label,
    required this.labelHalo,
    required this.placeLabel,
    required this.waterLabel,
    required this.poiLabel,
  });

  /// High contrast for reading outdoors: sand coloured main roads, dark
  /// labels on a white halo, outlined buildings.
  static const light = AppMapPalette(
    land: Color(0xFFF2F0EB),
    landuse: Color(0xFFEAE6DD),
    park: Color(0xFFC9DAB6),
    wood: Color(0xFFBDD0AA),
    grass: Color(0xFFD4E1C4),
    water: Color(0xFF9EC2D2),
    building: Color(0xFFDCD6CB),
    buildingOutline: Color(0xFFC4BCAE),
    road: Color(0xFFFFFFFF),
    roadCasing: Color(0xFFC9C1B4),
    majorRoad: Color(0xFFFBF0D9),
    majorRoadCasing: Color(0xFFD3BE93),
    motorway: Color(0xFFF8E2B8),
    motorwayCasing: Color(0xFFC6A56A),
    path: Color(0xFFA89F90),
    rail: Color(0xFFA39C91),
    label: Color(0xFF2E3135),
    labelHalo: Color(0xFFFFFFFF),
    placeLabel: Color(0xFF1A1C1E),
    waterLabel: Color(0xFF3E6F85),
    poiLabel: Color(0xFF6A6E74),
  );

  /// Ground with nothing else on it.
  final Color land;

  /// Cemeteries, hospitals, schools, sports grounds, industry.
  final Color landuse;
  final Color park;
  final Color wood;

  /// Grass, farmland and wetland.
  final Color grass;
  final Color water;
  final Color building;
  final Color buildingOutline;

  /// Streets and service roads.
  final Color road;
  final Color roadCasing;

  /// Trunk, primary, secondary and tertiary roads.
  final Color majorRoad;
  final Color majorRoadCasing;
  final Color motorway;
  final Color motorwayCasing;

  /// Footways, cycleways and tracks.
  final Color path;
  final Color rail;

  /// Street names, also the colour of country borders.
  final Color label;
  final Color labelHalo;

  /// Names of cities, towns and districts.
  final Color placeLabel;
  final Color waterLabel;

  /// Names of shops, sights and other places.
  final Color poiLabel;

  @override
  AppMapPalette copyWith({
    Color? land,
    Color? landuse,
    Color? park,
    Color? wood,
    Color? grass,
    Color? water,
    Color? building,
    Color? buildingOutline,
    Color? road,
    Color? roadCasing,
    Color? majorRoad,
    Color? majorRoadCasing,
    Color? motorway,
    Color? motorwayCasing,
    Color? path,
    Color? rail,
    Color? label,
    Color? labelHalo,
    Color? placeLabel,
    Color? waterLabel,
    Color? poiLabel,
  }) => AppMapPalette(
    land: land ?? this.land,
    landuse: landuse ?? this.landuse,
    park: park ?? this.park,
    wood: wood ?? this.wood,
    grass: grass ?? this.grass,
    water: water ?? this.water,
    building: building ?? this.building,
    buildingOutline: buildingOutline ?? this.buildingOutline,
    road: road ?? this.road,
    roadCasing: roadCasing ?? this.roadCasing,
    majorRoad: majorRoad ?? this.majorRoad,
    majorRoadCasing: majorRoadCasing ?? this.majorRoadCasing,
    motorway: motorway ?? this.motorway,
    motorwayCasing: motorwayCasing ?? this.motorwayCasing,
    path: path ?? this.path,
    rail: rail ?? this.rail,
    label: label ?? this.label,
    labelHalo: labelHalo ?? this.labelHalo,
    placeLabel: placeLabel ?? this.placeLabel,
    waterLabel: waterLabel ?? this.waterLabel,
    poiLabel: poiLabel ?? this.poiLabel,
  );

  /// Switches halfway instead of blending. A blended palette would be a new
  /// map style on every frame of a theme animation, and every new style
  /// redraws all map tiles.
  @override
  AppMapPalette lerp(AppMapPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
