import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_pressable.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

void main() {
  const raised = [
    NeoShadow(offset: Offset(4, 4), blur: 9, color: Color(0xFF000000)),
  ];
  const sunk = [
    NeoShadow(
      offset: Offset(4, 4),
      blur: 9,
      color: Color(0xFF000000),
      inset: true,
    ),
  ];

  Future<TestGesture> press(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Center(
            child: NeuPressable(
              onPressed: () {},
              shadows: raised,
              pressedShadows: sunk,
              width: 60,
              height: 60,
              child: const SizedBox(),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(NeuPressable)),
    );
    await tester.pump();
    return gesture;
  }

  List<NeoShadow> shown(WidgetTester tester) =>
      tester.widget<NeuSurface>(find.byType(NeuSurface)).shadows;

  testWidgets('a press sinks the surface in at once', (tester) async {
    final gesture = await press(tester);
    await tester.pump();

    expect(shown(tester), sunk);
    await gesture.up();
  });

  testWidgets('a released surface rises back gradually', (tester) async {
    final gesture = await press(tester);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await tester.pump(AppMotion.standard.short ~/ 4);
    expect(shown(tester).single.inset, isTrue);
    expect(shown(tester).single.offset.dx, lessThan(4));

    await tester.pumpAndSettle();
    expect(shown(tester), raised);
  });

  testWidgets('without animations a press sinks it at once', (tester) async {
    final gesture = await press(tester, disableAnimations: true);
    await tester.pump();

    expect(shown(tester), sunk);
    await gesture.up();
  });
}
