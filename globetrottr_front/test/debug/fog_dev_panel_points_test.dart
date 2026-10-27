import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';

import '../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the panel switches the recorded points on and off', (
    tester,
  ) async {
    final env = FogTestEnvironment();
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.pump();
    final toggle = find.widgetWithText(SwitchListTile, 'Show recorded points');
    expect(toggle, findsOneWidget);
    expect(container.read(recordedPointsVisibleProvider), isFalse);

    await tester.tap(toggle);
    await tester.pump();

    expect(container.read(recordedPointsVisibleProvider), isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pump();

    expect(container.read(recordedPointsVisibleProvider), isFalse);
  });
}
