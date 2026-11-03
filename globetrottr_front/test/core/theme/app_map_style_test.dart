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
    final style = AppMapStyle.json(AppMapPalette.light);

    final theme = ThemeReader(logger: logger).read(style);

    expect(logger.warnings, isEmpty);
    expect(theme.layers, hasLength(layersOf(style).length));
  });

  test('every layer reads the basemap source', () {
    final theme = AppMapStyle.themeOf(AppMapPalette.light);

    expect(theme.tileSources, {MapConfig.basemapSource});
  });

  test('colours come from the map palette', () {
    const land = Color(0xFF123456);
    const water = Color(0xFF0A0B0C);
    final style = AppMapStyle.json(
      AppMapPalette.light.copyWith(land: land, water: water),
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
      AppMapStyle.json(AppMapPalette.light),
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

  test('the theme is read once per palette', () {
    final palette = AppMapPalette.light.copyWith();

    expect(
      identical(AppMapStyle.themeOf(palette), AppMapStyle.themeOf(palette)),
      isTrue,
    );
  });
}
