import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/theme/app_map_palette.dart';
import 'package:globetrottr_front/core/theme/app_typography.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// The base map style for OpenMapTiles vector tiles, as a MapLibre style
/// built from an [AppMapPalette].
///
/// Zoom levels here are those of 512 px tiles, one less than the map's zoom;
/// the tile layer loads tiles with the matching offset. Only properties the
/// vector tile renderer supports are used, checked by a test.
abstract final class AppMapStyle {
  static final _themes = Expando<Map<String, Theme>>();

  /// The renderer theme for [palette] with labels in [languageCode], read
  /// once per palette instance and language.
  static Theme themeOf(AppMapPalette palette, String languageCode) =>
      (_themes[palette] ??= {})[languageCode] ??= ThemeReader().read(
        json(palette, languageCode),
      );

  static Map<String, dynamic> json(AppMapPalette p, String languageCode) {
    final layers = _layers(p, _nameIn(languageCode));
    return {
      'version': 8,
      'id': 'globetrottr',
      // The tile layer redraws its tiles only when the id or this version
      // changes, so it follows the content of the style.
      'metadata': {'version': jsonEncode(layers).hashCode.toRadixString(16)},
      'layers': layers,
    };
  }

  static List<Map<String, dynamic>> _layers(
    AppMapPalette p,
    List<Object> name,
  ) => [
    {
      'id': 'background',
      'type': 'background',
      'paint': {'background-color': _color(p.land)},
    },
    _fill('landuse', 'landuse', p.landuse, filter: _classIn(_landuse)),
    _fill(
      'grass',
      'landcover',
      p.grass,
      filter: _classIn(['grass', 'farmland', 'wetland']),
    ),
    _fill('wood', 'landcover', p.wood, filter: _classIn(['wood'])),
    _fill('park', 'park', p.park),
    _fill('water', 'water', p.water, filter: _notTunnel),
    _line('waterway', 'waterway', p.water, _waterwayWidth, _notTunnel),
    {
      ..._fill('building', 'building', p.building),
      'minzoom': 14,
      'paint': {
        'fill-color': _color(p.building),
        'fill-outline-color': _color(p.buildingOutline),
      },
    },
    {
      ..._line(
        'path',
        'transportation',
        p.path,
        _pathWidth,
        _all([
          _classIn(['path', 'track']),
          _notTunnel,
        ]),
      ),
      'minzoom': 14,
      'paint': {
        'line-color': _color(p.path),
        'line-width': _width(_pathWidth),
        'line-dasharray': [3, 2],
      },
    },
    {
      ..._line(
        'rail',
        'transportation',
        p.rail,
        _railWidth,
        _all([
          _classIn(['rail', 'transit']),
          _notTunnel,
        ]),
      ),
      'minzoom': 12,
    },
    _road('road-casing', _minor, p.roadCasing, _roadCasingWidth),
    _road('major-casing', _major, p.majorRoadCasing, _majorCasingWidth),
    _road('motorway-casing', _motorway, p.motorwayCasing, _motorwayCasingW),
    {..._road('road', _minor, p.road, _roadWidth), 'minzoom': 12},
    {..._road('major', _major, p.majorRoad, _majorWidth), 'minzoom': 8},
    _road('motorway', _motorway, p.motorway, _motorwayWidth),
    {
      'id': 'boundary',
      'type': 'line',
      'source': MapConfig.basemapSource,
      'source-layer': 'boundary',
      'filter': _all([
        [
          '==',
          ['get', 'admin_level'],
          2,
        ],
        [
          '!=',
          ['get', 'maritime'],
          1,
        ],
      ]),
      'paint': {
        'line-color': _color(p.label),
        'line-opacity': 0.35,
        'line-width': 1,
        'line-dasharray': [3, 2],
      },
    },
    _label(
      'waterway-name',
      'waterway',
      p.waterLabel,
      p.labelHalo,
      name,
      size: 12,
      minzoom: 13,
      onLine: true,
    ),
    _label(
      'water-name',
      'water_name',
      p.waterLabel,
      p.labelHalo,
      name,
      size: 12,
      filter: [
        '==',
        ['geometry-type'],
        'Point',
      ],
    ),
    _label(
      'road-name',
      'transportation_name',
      p.label,
      p.labelHalo,
      name,
      size: _width([
        [15, 9.5],
        [18, 12],
      ]),
      minzoom: 15,
      bold: true,
      onLine: true,
      filter: _classIn(_minor),
    ),
    _label(
      'major-name',
      'transportation_name',
      p.label,
      p.labelHalo,
      name,
      size: _width([
        [13, 10],
        [18, 13],
      ]),
      minzoom: 13,
      bold: true,
      onLine: true,
      filter: _classIn(_major),
    ),
    _label(
      'poi',
      'poi',
      p.poiLabel,
      p.labelHalo,
      name,
      size: 11,
      minzoom: 16,
      maxWidth: 8,
      filter: [
        '<=',
        ['get', 'rank'],
        14,
      ],
    ),
    _label(
      'district',
      'place',
      p.placeLabel,
      p.labelHalo,
      name,
      size: _width([
        [11, 10],
        [15, 13],
      ]),
      minzoom: 11,
      maxzoom: 16,
      bold: true,
      maxWidth: 7,
      filter: _classIn(['suburb', 'quarter', 'neighbourhood']),
      extraLayout: {
        'text-transform': 'uppercase',
        'text-letter-spacing': 1.5,
      },
      extraPaint: {'text-opacity': 0.75},
    ),
    _label(
      'town',
      'place',
      p.placeLabel,
      p.labelHalo,
      name,
      size: _width([
        [8, 11],
        [14, 15],
      ]),
      minzoom: 8,
      maxzoom: 15,
      bold: true,
      filter: _classIn(['town', 'village']),
    ),
    _label(
      'city',
      'place',
      p.placeLabel,
      p.labelHalo,
      name,
      size: _width([
        [4, 12],
        [12, 20],
      ]),
      maxzoom: 13,
      bold: true,
      filter: _classIn(['city']),
    ),
  ];

  static const _landuse = [
    'cemetery',
    'hospital',
    'school',
    'college',
    'university',
    'stadium',
    'pitch',
    'railway',
    'industrial',
  ];
  static const _minor = ['minor', 'service', 'busway'];
  static const _major = ['trunk', 'primary', 'secondary', 'tertiary'];
  static const _motorway = ['motorway'];

  // Line widths in pixels by zoom; a casing is the road plus about a pixel
  // on each side.
  static const _roadWidth = [
    [12, 0.5],
    [14, 2],
    [16, 6],
    [18, 18],
    [20, 48],
  ];
  static const _roadCasingWidth = [
    [12, 0.9],
    [14, 3.2],
    [16, 8],
    [18, 21],
    [20, 52],
  ];
  static const _majorWidth = [
    [8, 0.5],
    [11, 1.2],
    [13, 2.6],
    [15, 6.5],
    [17, 15],
    [19, 40],
  ];
  static const _majorCasingWidth = [
    [8, 0.9],
    [11, 1.9],
    [13, 3.8],
    [15, 8.6],
    [17, 18],
    [19, 44],
  ];
  static const _motorwayWidth = [
    [5, 0.6],
    [9, 1.5],
    [12, 3],
    [15, 8],
    [17, 16],
    [19, 42],
  ];
  static const _motorwayCasingW = [
    [5, 1],
    [9, 2.3],
    [12, 4.4],
    [15, 10],
    [17, 19],
    [19, 46],
  ];
  static const _pathWidth = [
    [14, 0.6],
    [16, 1.2],
    [18, 2.4],
  ];
  static const _railWidth = [
    [12, 0.6],
    [16, 1.4],
    [18, 2],
  ];
  static const _waterwayWidth = [
    [10, 0.5],
    [14, 1.5],
    [17, 4],
  ];

  static const _notTunnel = [
    '!=',
    ['get', 'brunnel'],
    'tunnel',
  ];

  /// The name in the app language where the map data has one, otherwise
  /// the local name.
  static List<Object> _nameIn(String languageCode) => [
    'coalesce',
    ['get', 'name:$languageCode'],
    ['get', 'name'],
  ];

  static List<Object> _width(List<List<num>> stops) => [
    'interpolate',
    ['exponential', 1.5],
    ['zoom'],
    for (final stop in stops) ...stop,
  ];

  static List<Object> _classIn(List<String> classes) => [
    'match',
    ['get', 'class'],
    classes,
    true,
    false,
  ];

  static List<Object> _all(List<Object> conditions) => ['all', ...conditions];

  static Map<String, dynamic> _fill(
    String id,
    String sourceLayer,
    Color color, {
    List<Object>? filter,
  }) => {
    'id': id,
    'type': 'fill',
    'source': MapConfig.basemapSource,
    'source-layer': sourceLayer,
    'filter': ?filter,
    'paint': {'fill-color': _color(color)},
  };

  static Map<String, dynamic> _line(
    String id,
    String sourceLayer,
    Color color,
    List<List<num>> width,
    List<Object> filter,
  ) => {
    'id': id,
    'type': 'line',
    'source': MapConfig.basemapSource,
    'source-layer': sourceLayer,
    'filter': filter,
    'layout': {'line-cap': 'round', 'line-join': 'round'},
    'paint': {'line-color': _color(color), 'line-width': _width(width)},
  };

  static Map<String, dynamic> _road(
    String id,
    List<String> classes,
    Color color,
    List<List<num>> width,
  ) => _line(
    id,
    'transportation',
    color,
    width,
    _all([_classIn(classes), _notTunnel]),
  );

  static Map<String, dynamic> _label(
    String id,
    String sourceLayer,
    Color color,
    Color halo,
    List<Object> name, {
    required Object size,
    double? minzoom,
    double? maxzoom,
    bool bold = false,
    bool onLine = false,
    double? maxWidth,
    List<Object>? filter,
    Map<String, Object> extraLayout = const {},
    Map<String, Object> extraPaint = const {},
  }) => {
    'id': id,
    'type': 'symbol',
    'source': MapConfig.basemapSource,
    'source-layer': sourceLayer,
    'minzoom': ?minzoom,
    'maxzoom': ?maxzoom,
    'filter': ?filter,
    'layout': {
      if (onLine) 'symbol-placement': 'line',
      'text-field': name,
      'text-font': [
        if (bold) AppTypography.mapBoldFontFamily else AppTypography.fontFamily,
      ],
      'text-size': size,
      'text-max-width': ?maxWidth,
      ...extraLayout,
    },
    'paint': {
      'text-color': _color(color),
      'text-halo-color': _color(halo),
      'text-halo-width': 1.6,
      ...extraPaint,
    },
  };

  static String _color(Color color) {
    final argb = color.toARGB32();
    final alpha = argb >>> 24;
    if (alpha == 0xFF) {
      return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    }
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return 'rgba($r, $g, $b, ${(alpha / 0xFF).toStringAsFixed(3)})';
  }
}
