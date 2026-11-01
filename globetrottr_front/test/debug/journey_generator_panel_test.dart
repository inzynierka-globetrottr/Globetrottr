import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/debug/widgets/journey_generator_panel.dart';

import '../support/fake_location_service.dart';

Future<void> _pumpPanel(WidgetTester tester) async {
  final env = FogTestEnvironment();
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: JourneyGeneratorPanel()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('journeyKmForSlider', () {
    test('spans 1 km to 100 000 km on a logarithmic scale', () {
      expect(journeyKmForSlider(0), 1);
      expect(journeyKmForSlider(1), 100000);
      expect(journeyKmForSlider(0.6), 1000);
    });

    test('rounds to readable steps', () {
      for (var t = 0.0; t <= 1; t += 0.01) {
        final km = journeyKmForSlider(t);
        final magnitude = km < 10 ? 1 : (km < 1000 ? 10 : 100);
        expect(km % magnitude, 0, reason: '$km');
      }
    });
  });

  testWidgets('the slider reaches both 1 km and 100 000 km', (tester) async {
    await _pumpPanel(tester);
    final slider = tester.widget<Slider>(find.byType(Slider));

    slider.onChanged!(0);
    await tester.pump();
    expect(find.text('Generate 1 km around my position'), findsOneWidget);

    slider.onChanged!(1);
    await tester.pump();
    expect(find.text('Generate 100000 km around my position'), findsOneWidget);
  });

  testWidgets('offers the surroundings and every continent', (tester) async {
    await _pumpPanel(tester);

    await tester.tap(find.byType(DropdownButton<ExplorerRegion?>));
    await tester.pumpAndSettle();

    expect(find.text('Around my position'), findsWidgets);
    for (final region in ExplorerRegion.all) {
      expect(find.text(region.name), findsWidgets);
    }
  });

  testWidgets('choosing a continent changes the button', (tester) async {
    await _pumpPanel(tester);
    await tester.tap(find.byType(DropdownButton<ExplorerRegion?>));
    await tester.pumpAndSettle();

    await tester.tap(find.text(ExplorerRegion.asia.name).last);
    await tester.pumpAndSettle();

    expect(find.textContaining('km across Asia'), findsOneWidget);
  });
}
