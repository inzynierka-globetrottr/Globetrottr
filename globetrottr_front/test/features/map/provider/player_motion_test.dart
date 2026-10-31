import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:latlong2/latlong.dart';

const _start = LatLng(50, 20);

/// A point the given number of meters north of the start.
LatLng _north(double meters) => LatLng(50 + meters / 111195, 20);

TrackLogEntry _entry(int id, LatLng at) => TrackLogEntry(
  id: id,
  sessionId: 'a',
  timestampMs: id,
  latitude: at.latitude,
  longitude: at.longitude,
);

double _metersNorth(LatLng at) => (at.latitude - 50) * 111195;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Duration now;
  late PlayerMotion motion;
  late List<TrackLogEntry> passed;

  setUp(() {
    now = Duration.zero;
    motion = PlayerMotion(animates: () => true, clock: () => now);
    passed = [];
    motion.passed.listen(passed.add);
  });

  tearDown(() => motion.dispose());

  void advance(Duration by) => motion.advance(by);

  /// The next fix, one second after the previous one.
  void fix(LatLng at, {TrackLogEntry? entry}) {
    now += const Duration(seconds: 1);
    motion.moveTo(at, entry: entry);
  }

  test('starts without a position', () {
    expect(motion.value, isNull);
  });

  test('the first position is taken at once', () {
    motion.moveTo(_start);

    expect(motion.value, _start);
  });

  test('glides to a new position instead of jumping', () {
    motion.moveTo(_start);
    fix(_north(14));

    advance(const Duration(milliseconds: 500));
    expect(_metersNorth(motion.value!), closeTo(7, 0.5));

    advance(const Duration(milliseconds: 500));
    expect(_metersNorth(motion.value!), closeTo(14, 0.1));
  });

  test('tells listeners about every step', () {
    motion.moveTo(_start);
    fix(_north(14));
    var steps = 0;
    motion.addListener(() => steps++);

    advance(const Duration(milliseconds: 16));
    advance(const Duration(milliseconds: 16));

    expect(steps, 2);
  });

  test('takes as long as the fixes are apart', () {
    motion.moveTo(_start);
    for (var i = 1; i <= 12; i++) {
      now += const Duration(milliseconds: 2000);
      motion.moveTo(_north(i * 10.0));
      motion.advance(const Duration(milliseconds: 2000));
    }

    now += const Duration(milliseconds: 2000);
    motion.moveTo(_north(130));
    motion.advance(const Duration(milliseconds: 1000));

    expect(_metersNorth(motion.value!), closeTo(125, 1.5));
  });

  test('an entry is passed only when the player reaches it', () {
    motion.moveTo(_start);
    final entry = _entry(1, _north(14));
    fix(_north(14), entry: entry);

    advance(const Duration(milliseconds: 900));
    expect(passed, isEmpty);

    advance(const Duration(milliseconds: 200));
    expect(passed, [entry]);
  });

  test('follows the fixes in order without cutting corners', () {
    motion.moveTo(_start);
    const corner = LatLng(50.0001, 20);
    const end = LatLng(50.0001, 20.0002);
    final first = _entry(1, corner);
    final second = _entry(2, end);
    fix(corner, entry: first);
    fix(end, entry: second);

    while (passed.isEmpty) {
      advance(const Duration(milliseconds: 16));
      expect(
        motion.value!.longitude == 20 || motion.value!.latitude > 50.00009,
        isTrue,
      );
    }
    expect(passed, [first]);

    advance(const Duration(seconds: 2));
    expect(passed, [first, second]);
    expect(motion.value, end);
  });

  test('a late fix speeds the player up to catch it', () {
    motion.moveTo(_start);
    fix(_north(10));
    advance(const Duration(milliseconds: 500));
    fix(_north(20));

    advance(const Duration(seconds: 1));

    expect(_metersNorth(motion.value!), closeTo(20, 0.1));
  });

  test('jumps over a gap instead of gliding across it', () {
    motion.moveTo(_start);
    final near = _entry(1, _north(14));
    final far = _entry(2, _north(2000));
    motion.moveTo(_north(14), entry: near);
    motion.moveTo(_north(2000), entry: far);

    expect(motion.value, _north(2000));
    expect(passed, [near, far]);
  });

  test('finish passes everything at once', () {
    motion.moveTo(_start);
    final entry = _entry(1, _north(14));
    motion.moveTo(_north(14), entry: entry);

    motion.finish();

    expect(motion.value, _north(14));
    expect(passed, [entry]);
  });

  test('without frames every position is taken at once', () {
    final hidden = PlayerMotion(animates: () => false, clock: () => now);
    addTearDown(hidden.dispose);
    final seen = <TrackLogEntry>[];
    hidden.passed.listen(seen.add);
    hidden.moveTo(_start);
    final entry = _entry(1, _north(14));

    hidden.moveTo(_north(14), entry: entry);

    expect(hidden.value, _north(14));
    expect(seen, [entry]);
  });
}
