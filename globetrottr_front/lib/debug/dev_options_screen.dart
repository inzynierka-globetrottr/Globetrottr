import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/debug/widgets/basemap_cache_dev_panel.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/debug/widgets/journey_generator_panel.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:go_router/go_router.dart';

class DevOptionsScreen extends ConsumerWidget {
  const DevOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).continueAsGuest();
              if (context.mounted) GoRouter.maybeOf(context)?.go('/map');
            },
            child: const Text('Continue as guest'),
          ),
          const Divider(height: 32),
          const JourneyGeneratorPanel(),
          const Divider(height: 32),
          const FogDevPanel(),
          const Divider(height: 32),
          const BasemapCacheDevPanel(),
        ],
      ),
    );
  }
}
