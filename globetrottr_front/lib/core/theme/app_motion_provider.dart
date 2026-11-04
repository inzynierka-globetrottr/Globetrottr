import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';

/// The steps of the duration scale. The camera flight and landing are the
/// same in both.
enum MotionPace {
  /// The scale of [AppMotion.standard].
  quick,

  /// The mock-up's CSS transitions, the first scale of the app.
  mockup;

  AppMotion applyTo(AppMotion motion) => switch (this) {
    quick => motion.copyWith(
      short: AppMotion.standard.short,
      medium: AppMotion.standard.medium,
      long: AppMotion.standard.long,
    ),
    mockup => motion.copyWith(
      short: const Duration(milliseconds: 200),
      medium: const Duration(milliseconds: 240),
      long: const Duration(milliseconds: 280),
    ),
  };
}

/// How a pressed button comes back up.
enum PressFeel {
  /// Rises back in the short step of the scale.
  smooth,

  /// Rises back quicker than any step.
  quick,

  /// Is raised again at once, after the shortest hold.
  instant,

  /// Is sunk only while the finger is down, so a quick tap may not show.
  none;

  static const _quickRise = Duration(milliseconds: 100);

  AppMotion applyTo(AppMotion motion) => switch (this) {
    smooth => motion.copyWith(
      pressRise: motion.short,
      pressHold: AppMotion.standard.pressHold,
    ),
    quick => motion.copyWith(
      pressRise: _quickRise,
      pressHold: AppMotion.standard.pressHold,
    ),
    instant => motion.copyWith(
      pressRise: Duration.zero,
      pressHold: AppMotion.standard.pressHold,
    ),
    none => motion.copyWith(pressRise: Duration.zero, pressHold: Duration.zero),
  };
}

/// The variants of the motion picked on the dev screen "Animations" to
/// compare them on a phone. Temporary, until one of each is chosen.
@immutable
class MotionChoices {
  const MotionChoices({
    this.pace = MotionPace.quick,
    this.press = PressFeel.instant,
    this.navPill = NavPillMotion.jump,
    this.tab = TabTransition.instant,
    this.deeper = DeeperTransition.instant,
  });

  final MotionPace pace;
  final PressFeel press;
  final NavPillMotion navPill;
  final TabTransition tab;
  final DeeperTransition deeper;

  /// The press follows the pace, as a smooth one rises in its short step.
  AppMotion get motion => press.applyTo(
    pace.applyTo(
      AppMotion.standard.copyWith(
        navPill: navPill,
        tabTransition: tab,
        deeperTransition: deeper,
      ),
    ),
  );

  MotionChoices copyWith({
    MotionPace? pace,
    PressFeel? press,
    NavPillMotion? navPill,
    TabTransition? tab,
    DeeperTransition? deeper,
  }) => MotionChoices(
    pace: pace ?? this.pace,
    press: press ?? this.press,
    navPill: navPill ?? this.navPill,
    tab: tab ?? this.tab,
    deeper: deeper ?? this.deeper,
  );
}

class MotionChoicesNotifier extends Notifier<MotionChoices> {
  @override
  MotionChoices build() => const MotionChoices();

  void choose({
    MotionPace? pace,
    PressFeel? press,
    NavPillMotion? navPill,
    TabTransition? tab,
    DeeperTransition? deeper,
  }) => state = state.copyWith(
    pace: pace,
    press: press,
    navPill: navPill,
    tab: tab,
    deeper: deeper,
  );
}

final motionChoicesProvider =
    NotifierProvider<MotionChoicesNotifier, MotionChoices>(
      MotionChoicesNotifier.new,
    );

/// The motion of the app theme.
final appMotionProvider = Provider<AppMotion>(
  (ref) => ref.watch(motionChoicesProvider).motion,
);
