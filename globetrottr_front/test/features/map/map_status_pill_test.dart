import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_status_pill.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  Future<void> show(WidgetTester tester, {required bool recording}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MapStatusPillView(
                share: 0.42,
                regionName: 'Kazimierz',
                newArea: 0.25,
                recording: recording,
                onRecord: () {},
              ),
            ),
          ),
        ),
      );

  testWidgets('the walk area unfolds next to the district', (tester) async {
    await show(tester, recording: false);
    final alone = tester.getSize(find.text('Kazimierz')).width;
    expect(find.text('new ground'), findsNothing);

    await show(tester, recording: true);
    await tester.pump(AppMotion.standard.long ~/ 2);
    expect(find.text('new ground'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('new ground'), findsOneWidget);
    expect(tester.getSize(find.text('Kazimierz')).width, lessThan(alone + 1));

    await show(tester, recording: false);
    await tester.pumpAndSettle();
    expect(find.text('new ground'), findsNothing);
  });

  testWidgets('the record button turns into the stop button', (tester) async {
    await show(tester, recording: false);
    await show(tester, recording: true);
    await tester.pump(AppMotion.standard.short ~/ 2);

    expect(find.bySemanticsLabel('Stop the walk'), findsOneWidget);
  });
}
