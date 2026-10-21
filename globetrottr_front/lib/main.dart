import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouter);

    return MaterialApp.router(
      title: 'Globetrottr',
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
