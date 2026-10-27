import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/features/profile/screens/widgets/settings_dialog.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  Widget buildTestableWidget({required WidgetRefCallback onRef}) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          onRef(ref);
          final locale = ref.watch(localeProvider);

          return MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsDialog()),
          );
        },
      ),
    );
  }

  testWidgets('SettingsDialog renders and changes locale dynamically', (
    tester,
  ) async {
    WidgetRef? widgetRef;

    await tester.pumpWidget(
      buildTestableWidget(
        onRef: (ref) {
          widgetRef = ref;
        },
      ),
    );
    await tester.pumpAndSettle();

    // Default English UI
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Polski'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);

    // Tap Polish option
    await tester.tap(find.text('Polski'));
    await tester.pumpAndSettle();

    // Should now display Polish UI
    expect(widgetRef?.read(localeProvider), const Locale('pl'));
    expect(find.text('Ustawienia'), findsOneWidget);
    expect(find.text('Język'), findsOneWidget);
    expect(find.text('Domyślny systemu'), findsOneWidget);

    // Tap English option
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(widgetRef?.read(localeProvider), const Locale('en'));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}

typedef WidgetRefCallback = void Function(WidgetRef ref);
