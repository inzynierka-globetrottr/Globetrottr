import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';
import 'package:globetrottr_front/features/map/screens/widgets/layers_sheet.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_status_pill.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/quests/provider/quest_point_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_flag.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_point_layer.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

import '../../support/fake_location_service.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        syncServiceProvider.overrideWithValue(FakeSyncService()),
        questServiceProvider.overrideWithValue(FakeQuestService()),
        questPointProvider.overrideWithValue(
          const QuestPoint(position: LatLng(50.05, 19.93), distanceMeters: 280),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pill shows neutral values and starts and stops a walk', (
    tester,
  ) async {
    await pump(tester, const MapStatusPill());

    expect(find.text('—%'), findsOneWidget);
    expect(find.text('Your area'), findsOneWidget);
    expect(find.text('new ground'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Start the walk'));
    await tester.pumpAndSettle();

    expect(container.read(locationProvider).isRecording, isTrue);
    expect(find.text('+— km²'), findsOneWidget);
    expect(find.text('new ground'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Stop the walk'));
    await tester.pumpAndSettle();

    expect(container.read(locationProvider).isRecording, isFalse);
  });

  testWidgets('the quest flag grows into a card with the progress', (
    tester,
  ) async {
    var open = false;
    var details = 0;
    const quest = Quest(
      id: 1,
      title: 'Spacer Bulwarami',
      type: 'DISCOVER',
      rewardPoints: 10,
      progress: 0.6,
      isStarted: true,
      isCompleted: false,
    );
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => QuestFlag(
          quest: quest,
          open: open,
          onToggle: () => setState(() => open = !open),
          onDetails: () => details++,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Active quest: Spacer Bulwarami'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    expect(find.text('60%'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Quest details'));
    expect(details, 1);
  });

  testWidgets('planned map views only say they are coming', (tester) async {
    await pump(tester, const LayersSheet());

    await tester.tap(find.text('Heatmap'));
    await tester.pump();

    expect(find.text('This view will be available soon.'), findsOneWidget);
    expect(container.read(mapViewProvider), MapView.fog);
  });

  testWidgets('tapping the quest point opens the quest', (tester) async {
    var tapped = false;
    await pump(
      tester,
      FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(50.05, 19.93),
          initialZoom: 15,
        ),
        children: [
          QuestPointLayer(selected: false, onTap: () => tapped = true),
        ],
      ),
    );

    expect(find.text('Quest · 280 m'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Quest · 280 m'));
    expect(tapped, isTrue);
  });
}
