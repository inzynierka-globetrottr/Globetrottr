import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// When the installed package was last updated, in local time. A hot restart
/// changes the code only until the app is closed, so this is what a new start
/// really runs.
final appInstalledAtProvider = FutureProvider<DateTime?>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.updateTime?.toLocal();
});

String buildStampText(DateTime installed) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'APK ${two(installed.day)}.${two(installed.month)} '
      '${two(installed.hour)}:${two(installed.minute)}';
}

/// Small label next to the debug banner, for telling builds apart on a device.
/// Place it in a `Stack` above the app.
class BuildStamp extends ConsumerWidget {
  const BuildStamp({super.key});

  static const double _bannerWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installed = ref.watch(appInstalledAtProvider).value;
    if (installed == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.paddingOf(context).top,
      right: _bannerWidth,
      child: IgnorePointer(
        child: ColoredBox(
          color: AppColors.devGridLabelBackground,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              buildStampText(installed),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.devButton,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
