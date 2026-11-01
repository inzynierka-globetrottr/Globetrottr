import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/screens/login_screen.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

import '../../support/fake_auth_service.dart';

void main() {
  Future<Scaffold> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );
    return tester.widget<Scaffold>(find.byType(Scaffold).first);
  }

  tearDown(dotenv.clean);

  testWidgets('without dev mode the login screen has no floating button', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'DEV_MODE=false');

    final scaffold = await pumpLogin(tester);

    expect(scaffold.floatingActionButton, isNull);
  });

  testWidgets('in dev mode the login screen shows the dev button', (
    tester,
  ) async {
    dotenv.loadFromString(envString: 'DEV_MODE=true');

    final scaffold = await pumpLogin(tester);

    expect(scaffold.floatingActionButton, isNotNull);
    expect(find.text('DEV MODE'), findsOneWidget);
  });
}
