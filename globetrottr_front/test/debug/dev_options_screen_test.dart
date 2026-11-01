import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/dev_options_screen.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/debug/widgets/journey_generator_panel.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';

import '../support/fake_auth_service.dart';
import '../support/fake_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('has the fog tools and exactly one journey generator', (
    tester,
  ) async {
    final env = FogTestEnvironment();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides,
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const MaterialApp(home: DevOptionsScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(FogDevPanel, skipOffstage: false), findsOneWidget);
    expect(
      find.byType(JourneyGeneratorPanel, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Generate', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.textContaining('SQLite', skipOffstage: false), findsNothing);
  });

  testWidgets('continuing without login authenticates the app', (
    tester,
  ) async {
    final env = FogTestEnvironment();
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DevOptionsScreen()),
      ),
    );
    await tester.pump();
    final button = find.text('Continue without login');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pump();

    expect(container.read(authProvider).isAuthenticated, isTrue);
  });
}
