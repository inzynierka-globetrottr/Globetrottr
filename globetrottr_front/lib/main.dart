import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/silent_image_errors.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/core/router/app_router.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/debug/widgets/build_stamp.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/app_open_recorder.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    FlutterError.onError = skipSilentImageErrors(FlutterError.onError);
  }
  await dotenv.load();
  final initialLocale = await loadPersistedLocale();

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(initialLocale),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouter);
    final locale = ref.watch(localeProvider);

    return AppOpenRecorder(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: kDebugMode
            ? (context, child) => Stack(
                fit: StackFit.expand,
                children: [?child, const BuildStamp()],
              )
            : null,
      ),
    );
  }
}
