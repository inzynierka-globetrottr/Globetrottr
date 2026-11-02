import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/router/auth_redirect.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  final now = DateTime(2026, 11, 2, 12);

  setUp(() => dotenv.loadFromString(envString: 'DEV_MODE=false'));
  tearDown(dotenv.clean);

  Future<GoRouter> pumpApp(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Created inside the test, so the session check completes in its fake
    // time.
    auth = FakeAuthService();

    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: location,
      refreshListenable: _AuthListenable(container),
      redirect: (_, state) =>
          authRedirect(container.read(authProvider), state.matchedLocation),
      routes: [
        authRoute,
        GoRoute(path: '/map', builder: (_, _) => const Text('map')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    // The session check finds no account.
    auth.sessionCheck.complete(null);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('skipping the login opens the map as a guest', (tester) async {
    await pumpApp(tester, AuthRoutes.login);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('map'), findsOneWidget);
    expect(auth.guest, isTrue);
  });

  testWidgets('signing in without a login shows what is missing', (
    tester,
  ) async {
    await pumpApp(tester, AuthRoutes.login);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Login is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('a new account goes on to the code sent to its address', (
    tester,
  ) async {
    await pumpApp(tester, AuthRoutes.register);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'odkrywca');
    await tester.enterText(fields.at(1), 'Odkrywca@Poczta.pl');
    await tester.enterText(fields.at(2), 'Szlak26!');
    await tester.pump();
    expect(find.textContaining('good'), findsOneWidget);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Check your inbox'), findsOneWidget);
    expect(find.text('odkrywca@poczta.pl', findRichText: true), findsNothing);
    expect(
      find.textContaining('odkrywca@poczta.pl', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Resend in 1:00'), findsOneWidget);
  });

  testWidgets('the right code opens the map', (tester) async {
    await pumpApp(tester, AuthRoutes.register);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'odkrywca');
    await tester.enterText(fields.at(1), 'odkrywca@poczta.pl');
    await tester.enterText(fields.at(2), 'Szlak26!');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Verify'));
    await tester.pump();
    expect(find.text('Enter all 6 digits of the code.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '482193');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(auth.verifications.single.code, '482193');
    expect(find.text('map'), findsOneWidget);
  });
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(ProviderContainer container) {
    container.listen(authProvider, (_, _) => notifyListeners());
  }
}
