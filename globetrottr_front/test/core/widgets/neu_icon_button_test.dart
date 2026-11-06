import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

void main() {
  final shadows = AppShadows.fromPalette(AppPalette.light);

  Future<List<NeoShadow>> pressedShadows(
    WidgetTester tester,
    NeuFill fill,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Center(
          child: NeuIconButton(
            fill: fill,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NeuIconButton)),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<NeuSurface>(find.byType(NeuSurface));
    await gesture.up();
    return surface.shadows;
  }

  testWidgets('a page button sinks into the page tint while pressed', (
    tester,
  ) async {
    expect(
      await pressedShadows(tester, NeuFill.page),
      shadows.inset(NeoDepth.xs),
    );
  });

  testWidgets('a filled button sinks into a dark shade while pressed', (
    tester,
  ) async {
    for (final fill in [NeuFill.accent, NeuFill.danger]) {
      expect(
        await pressedShadows(tester, fill),
        shadows.insetAccent(NeoDepth.xs),
      );
    }
  });
}
