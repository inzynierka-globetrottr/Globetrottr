import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_route_bar.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  Future<void> show(WidgetTester tester, double progress) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: QuestRouteBar(progress: progress)),
    ),
  );

  double barFill(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .widthFactor!;

  testWidgets('the bar fills up to a new progress gradually', (tester) async {
    await show(tester, 0.4);
    expect(barFill(tester), 0.4);

    await show(tester, 0.6);
    await tester.pump(AppMotion.standard.long ~/ 2);
    expect(barFill(tester), inExclusiveRange(0.4, 0.6));

    await tester.pumpAndSettle();
    expect(barFill(tester), 0.6);
    expect(find.text('60%'), findsOneWidget);
  });
}
