import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_palette.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

void main() {
  final shadows = AppShadows.fromPalette(AppPalette.light);

  Future<void> pump(WidgetTester tester, Widget surface) =>
      tester.pumpWidget(MaterialApp(home: Center(child: surface)));

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byType(NeuSurface),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;

  testWidgets('outer shadows become box shadows on the page colour', (
    tester,
  ) async {
    await pump(
      tester,
      NeuSurface(
        shadows: shadows.raised(NeoDepth.xl),
        borderRadius: BorderRadius.circular(28),
        child: const SizedBox(width: 40, height: 40),
      ),
    );

    final decoration = decorationOf(tester);
    expect(decoration.boxShadow, hasLength(2));
    expect(decoration.color, AppPalette.light.background);
    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect(find.byType(NeuInsetShadow), findsNothing);
  });

  testWidgets('inset shadows are painted inside the shape', (tester) async {
    await pump(
      tester,
      NeuSurface(
        shadows: shadows.inset(NeoDepth.md),
        borderRadius: BorderRadius.circular(22),
        child: const SizedBox(width: 40, height: 40),
      ),
    );

    expect(decorationOf(tester).boxShadow, isEmpty);
    expect(find.byType(NeuInsetShadow), findsOneWidget);
  });

  testWidgets('a circle has no corner radius', (tester) async {
    await pump(
      tester,
      NeuSurface.circle(
        shadows: shadows.raisedAccent(NeoDepth.sm),
        color: AppPalette.light.accent,
        child: const SizedBox(width: 52, height: 52),
      ),
    );

    final decoration = decorationOf(tester);
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, AppPalette.light.accent);
    expect(decoration.boxShadow, hasLength(2));
    expect(find.byType(NeuInsetShadow), findsOneWidget);
  });
}
