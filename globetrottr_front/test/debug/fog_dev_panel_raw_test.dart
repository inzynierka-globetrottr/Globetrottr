import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';

import '../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the panel switches the raw fog pixels on and off', (
    tester,
  ) async {
    final env = FogTestEnvironment();
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    container.read(fogRenderOptionsProvider.notifier).options = container
        .read(fogRenderOptionsProvider)
        .copyWith(softEdgeMeters: 7);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.pump();
    final toggle = find.widgetWithText(SwitchListTile, 'Raw fog pixels');
    expect(toggle, findsOneWidget);
    expect(container.read(fogRenderOptionsProvider).rawPixels, isFalse);

    await tester.tap(toggle);
    await tester.pump();

    final options = container.read(fogRenderOptionsProvider);
    expect(options.rawPixels, isTrue);
    expect(options.softEdgeMeters, 7);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);

    await tester.tap(toggle);
    await tester.pump();

    expect(container.read(fogRenderOptionsProvider).rawPixels, isFalse);
  });
}
