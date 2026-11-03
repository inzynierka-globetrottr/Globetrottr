import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_map_palette.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/theme/app_typography.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

void main() {
  Future<BuildContext> pumpWith(WidgetTester tester, ThemeData? theme) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  test('a different accent changes only the accent', () {
    const accent = Color(0xFF2D4A8A);
    final palette = AppPalette.light.copyWith(accent: accent);

    expect(palette.accent, accent);
    expect(palette.background, AppPalette.light.background);
    expect(palette.text, AppPalette.light.text);
  });

  test('the theme is built from one palette', () {
    final theme = AppTheme.from(AppPalette.light);

    expect(theme.scaffoldBackgroundColor, AppPalette.light.background);
    expect(theme.extension<AppPalette>(), AppPalette.light);
    expect(theme.extension<AppShadows>()!.dark, AppPalette.light.shadowDark);
    expect(
      theme.extension<AppTypography>()!.body.color,
      AppPalette.light.textMuted,
    );
  });

  test('the theme carries the map palette', () {
    const land = Color(0xFF223344);
    final map = AppMapPalette.light.copyWith(land: land);

    expect(
      AppTheme.from(AppPalette.light).extension<AppMapPalette>(),
      AppMapPalette.light,
    );
    expect(
      AppTheme.from(
        AppPalette.light,
        map: map,
      ).extension<AppMapPalette>()!.land,
      land,
    );
  });

  test('the map palette switches at once instead of blending, so a theme '
      'animation does not rebuild the map style on every frame', () {
    final dark = AppMapPalette.light.copyWith(land: const Color(0xFF101010));

    for (final t in [0.0, 0.2, 0.49]) {
      expect(
        identical(AppMapPalette.light.lerp(dark, t), AppMapPalette.light),
        isTrue,
      );
    }
    for (final t in [0.5, 0.8, 1.0]) {
      expect(identical(AppMapPalette.light.lerp(dark, t), dark), isTrue);
    }
  });

  test('every text style uses the app font', () {
    final typography = AppTypography.fromPalette(AppPalette.light);

    for (final style in typography.all) {
      expect(style.fontFamily, AppTypography.fontFamily);
    }
  });

  testWidgets('widgets read the tokens of the app theme', (tester) async {
    const accent = Color(0xFF693B6E);
    final context = await pumpWith(
      tester,
      AppTheme.from(AppPalette.light.copyWith(accent: accent)),
    );

    expect(context.palette.accent, accent);
    expect(context.typography.button.color, AppPalette.light.onAccent);
  });

  testWidgets('without the app theme the light tokens are used', (
    tester,
  ) async {
    final context = await pumpWith(tester, null);

    expect(context.palette, AppPalette.light);
    expect(context.mapPalette, AppMapPalette.light);
    expect(context.shadows.dark, AppPalette.light.shadowDark);
    expect(context.typography.display.fontSize, 32);
  });
}
