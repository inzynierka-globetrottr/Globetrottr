import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';

import '../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the panel switches the tile grid on and off', (tester) async {
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
    final toggle = find.widgetWithText(SwitchListTile, 'Show tile grid');
    expect(toggle, findsOneWidget);
    expect(container.read(fogRenderOptionsProvider).showGrid, isFalse);

    await tester.tap(toggle);
    await tester.pump();

    expect(container.read(fogRenderOptionsProvider).showGrid, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pump();

    expect(container.read(fogRenderOptionsProvider).showGrid, isFalse);
  });

  testWidgets('switching the grid keeps the other render options', (
    tester,
  ) async {
    final env = FogTestEnvironment();
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    container.read(fogRenderOptionsProvider.notifier).options = container
        .read(fogRenderOptionsProvider)
        .copyWith(softEdge: false, softEdgeMeters: 7);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Show tile grid'));
    await tester.pump();

    final options = container.read(fogRenderOptionsProvider);
    expect(options.showGrid, isTrue);
    expect(options.softEdge, isFalse);
    expect(options.softEdgeMeters, 7);
  });
}
