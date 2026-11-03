import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_steps.dart';

void main() {
  Future<void> show(WidgetTester tester, List<bool> visited) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: QuestSteps(visited: visited, next: visited.indexOf(false)),
            ),
          ),
        ),
      );

  List<Size> sizes(WidgetTester tester) => [
    for (final element in find.byType(NeuSurface).evaluate())
      tester.getSize(find.byWidget(element.widget)),
  ];

  testWidgets('lines stretch between the dots', (tester) async {
    await show(tester, [true, false, false]);

    final lines = sizes(tester).where((s) => s.height < 10);
    expect(lines, hasLength(2));
    expect(lines.every((s) => s.width > 50), isTrue);
  });

  testWidgets('a newly visited step ends in its new look', (tester) async {
    await show(tester, [true, false, false]);
    await show(tester, [true, true, false]);
    await tester.pumpAndSettle();

    final filled = tester
        .widgetList<NeuSurface>(find.byType(NeuSurface))
        .where((s) => s.color == AppTheme.light.colorScheme.primary);
    expect(filled, hasLength(3));
  });
}
