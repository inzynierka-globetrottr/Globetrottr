import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/commute_generator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const home = LatLng(50.0614, 19.9383);

  test('every trip is its own session and the same seed repeats', () {
    final first = generateCommutes(home: home, trips: 20, seed: 3);
    final again = generateCommutes(home: home, trips: 20, seed: 3);

    expect(first.map((e) => e.sessionId).toSet(), hasLength(20));
    expect(first.length, again.length);
    expect(first.last.latitude, again.last.latitude);
  });

  test('stays near home and moves in small steps', () {
    final entries = generateCommutes(home: home, trips: 30, routes: 10);
    const distance = Distance();

    for (var i = 1; i < entries.length; i++) {
      final a = entries[i - 1];
      final b = entries[i];
      if (a.sessionId != b.sessionId) continue;
      final step = distance(
        LatLng(a.latitude, a.longitude),
        LatLng(b.latitude, b.longitude),
      );
      expect(step, lessThan(40));
    }
    for (final entry in entries) {
      final away = distance(home, LatLng(entry.latitude, entry.longitude));
      expect(away, lessThan(30000));
    }
  });
}
