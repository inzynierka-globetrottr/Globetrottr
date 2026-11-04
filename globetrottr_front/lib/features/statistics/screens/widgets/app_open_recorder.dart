import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';

/// Counts the app-open streak when the app starts and whenever it comes
/// back to the foreground, since the process can stay alive for days.
class AppOpenRecorder extends ConsumerStatefulWidget {
  const AppOpenRecorder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppOpenRecorder> createState() => _AppOpenRecorderState();
}

class _AppOpenRecorderState extends ConsumerState<AppOpenRecorder> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _record);
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  void _record() {
    ref.read(streakStatsProvider.notifier).recordAppOpen().catchError((
      Object error,
    ) {
      debugPrint('Recording the app open failed: $error');
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
