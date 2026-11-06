import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_motion_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  AppMotion motion() => container.read(appMotionProvider);
  MotionChoicesNotifier choices() =>
      container.read(motionChoicesProvider.notifier);

  test('the app starts with the standard motion', () {
    expect(motion(), AppMotion.standard);
  });

  test('the pace of the mock-up brings back its durations', () {
    choices().choose(pace: MotionPace.mockup);

    expect(motion().short, const Duration(milliseconds: 200));
    expect(motion().medium, const Duration(milliseconds: 240));
    expect(motion().long, const Duration(milliseconds: 280));
    expect(motion().flight, AppMotion.standard.flight);
    expect(motion().landing, AppMotion.standard.landing);
  });

  test('a smooth press rises back in the short step of the pace', () {
    choices().choose(pace: MotionPace.mockup, press: PressFeel.smooth);

    expect(motion().pressRise, const Duration(milliseconds: 200));
  });

  test('each press feel sets how a button rises and how long it holds', () {
    choices().choose(press: PressFeel.quick);
    expect(motion().pressRise, const Duration(milliseconds: 100));
    expect(motion().pressHold, AppMotion.standard.pressHold);

    choices().choose(press: PressFeel.instant);
    expect(motion().pressRise, Duration.zero);
    expect(motion().pressHold, AppMotion.standard.pressHold);

    choices().choose(press: PressFeel.none);
    expect(motion().pressRise, Duration.zero);
    expect(motion().pressHold, Duration.zero);
  });

  test('a choice keeps the others', () {
    choices().choose(
      pace: MotionPace.mockup,
      navPill: NavPillMotion.slide,
      tab: TabTransition.fadeThrough,
    );
    choices().choose(deeper: DeeperTransition.zoom);

    final chosen = container.read(motionChoicesProvider);
    expect(chosen.pace, MotionPace.mockup);
    expect(chosen.navPill, NavPillMotion.slide);
    expect(chosen.tab, TabTransition.fadeThrough);
    expect(motion().navPill, NavPillMotion.slide);
    expect(motion().tabTransition, TabTransition.fadeThrough);
    expect(motion().deeperTransition, DeeperTransition.zoom);
  });
}
