import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';

/// The motion of the app theme. The dev screen "Animations" changes it to
/// compare transitions on a phone.
class AppMotionNotifier extends Notifier<AppMotion> {
  @override
  AppMotion build() => AppMotion.standard;

  void choose({TabTransition? tab, DeeperTransition? deeper}) =>
      state = state.copyWith(tabTransition: tab, deeperTransition: deeper);
}

final appMotionProvider = NotifierProvider<AppMotionNotifier, AppMotion>(
  AppMotionNotifier.new,
);
