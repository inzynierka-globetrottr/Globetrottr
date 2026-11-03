import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/theme/app_map_palette.dart';
import 'package:globetrottr_front/core/theme/app_map_style.dart';
import 'package:globetrottr_front/core/theme/app_typography.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

class _RecordingLogger implements Logger {
  final warnings = <String>[];

  @override
  void log(MessageFunction message) {}

  @override
  void warn(MessageFunction message) => warnings.add(message());
}

void main() {
  List<Map<String, dynamic>> layersOf(Map<String, dynamic> style) =>
      (style['layers'] as List).cast<Map<String, dynamic>>();

  test('the renderer understands every layer of the style', () {
    final logger = _RecordingLogger();
    final style = AppMapStyle.json(AppMapPalette.light, 'pl');

    final theme = ThemeReader(logger: logger).read(style);

    expect(logger.warnings, isEmpty);
    expect(theme.layers, hasLength(layersOf(style).length));
  });

  test('every layer reads the basemap source', () {
    final theme = AppMapStyle.themeOf(AppMapPalette.light, 'pl');

    expect(theme.tileSources, {MapConfig.basemapSource});
  });

  test('colours come from the map palette', () {
    const land = Color(0xFF123456);
    const water = Color(0xFF0A0B0C);
    final style = AppMapStyle.json(
      AppMapPalette.light.copyWith(land: land, water: water),
      'pl',
    );
    final layers = layersOf(style);
    Map<String, dynamic> paintOf(String id) =>
        layers.firstWhere((l) => l['id'] == id)['paint']
            as Map<String, dynamic>;

    expect(paintOf('background')['background-color'], '#123456');
    expect(paintOf('water')['fill-color'], '#0A0B0C');
  });

  test('labels use the app font', () {
    final symbols = layersOf(
      AppMapStyle.json(AppMapPalette.light, 'pl'),
    ).where((l) => l['type'] == 'symbol');

    expect(symbols, isNotEmpty);
    for (final layer in symbols) {
      final fonts = (layer['layout'] as Map)['text-font'] as List;
      expect(
        fonts.single,
        anyOf(AppTypography.fontFamily, AppTypography.mapBoldFontFamily),
        reason: layer['id'] as String,
      );
    }
  });

  test('translucent colours keep their alpha', () {
    const water = Color(0x809EC2D2);
    final logger = _RecordingLogger();
    final style = AppMapStyle.json(
      AppMapPalette.light.copyWith(water: water),
      'pl',
    );
    final fill = layersOf(style).firstWhere((l) => l['id'] == 'water');

    expect((fill['paint'] as Map)['fill-color'], 'rgba(158, 194, 210, 0.502)');
    ThemeReader(logger: logger).read(style);
    expect(logger.warnings, isEmpty);
  });

  test('country borders skip the maritime ones', () {
    final boundary = layersOf(
      AppMapStyle.json(AppMapPalette.light, 'pl'),
    ).firstWhere((l) => l['id'] == 'boundary');

    expect(
      boundary['filter'],
      containsAll([
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
    );
  });

  test('labels are in the app language, with the local name as fallback', () {
    final style = AppMapStyle.json(AppMapPalette.light, 'en');
    final symbols = layersOf(style).where((l) => l['type'] == 'symbol');

    expect(symbols, isNotEmpty);
    for (final layer in symbols) {
      expect((layer['layout'] as Map)['text-field'], [
        'coalesce',
        ['get', 'name:en'],
        ['get', 'name'],
      ], reason: layer['id'] as String);
    }
  });

  test('the theme is read once per palette and language', () {
    final palette = AppMapPalette.light.copyWith();
    final polish = AppMapStyle.themeOf(palette, 'pl');

    expect(identical(polish, AppMapStyle.themeOf(palette, 'pl')), isTrue);
    expect(AppMapStyle.themeOf(palette, 'en').version, isNot(polish.version));
  });
}
