import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/fog/data/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:latlong2/latlong.dart';

import '../../../support/fog_test_helpers.dart';

const _maxCached = 32;
const _maxDirty = 16;
const _budget = 32;

Future<FogStore> _open(
  InMemoryFogTileStorage tiles, {
  int importTileBudget = _budget,
}) {
  return FogStore.open(
    tiles,
    maxCachedTiles: _maxCached,
    maxDirtyTiles: _maxDirty,
    importTileBudget: importTileBudget,
    flushDelay: const Duration(hours: 1),
  );
}

/// A fast journey: fixes one second apart, so 2000 of them cover tens of
/// kilometres and hundreds of tiles.
List<TrackLogEntry> _fastJourney(double km) {
  final journey = ExplorerJourney(
    start: const LatLng(krakowLat, krakowLng),
    totalKm: km,
    spacingFollowsSpeed: true,
  );
  return [
    for (final (i, e) in journey.next(maxPoints: 1 << 30).indexed)
      e.withId(i + 1),
  ];
}

void main() {
  test('a long import never holds more than its budget of tiles', () async {
    final store = await _open(InMemoryFogTileStorage());
    final entries = _fastJourney(150);

    await store.importEntries(entries, useIsolate: false);
    await store.flush();

    expect(store.totalAreaM2, greaterThan(0));
    expect(
      store.diagnostics.peakCachedTiles,
      lessThanOrEqualTo(_maxCached + 3 * _budget),
    );
    await store.dispose();
  });

  test('a replay of a long log never holds more than its budget', () async {
    final log = InMemoryTrackLogStorage();
    await log.appendAll(_fastJourney(150));
    final store = await _open(InMemoryFogTileStorage());

    await store.replayFrom(log, useIsolate: false);

    expect(store.lastAppliedLogId, await log.lastId());
    expect(
      store.diagnostics.peakCachedTiles,
      lessThanOrEqualTo(_maxCached + 3 * _budget),
    );
    await store.dispose();
  });

  test('splitting the import by the budget draws the same fog', () async {
    final entries = _fastJourney(40);
    final smallTiles = InMemoryFogTileStorage();
    final small = await _open(smallTiles);
    final wholeTiles = InMemoryFogTileStorage();
    final whole = await _open(wholeTiles, importTileBudget: 1 << 20);

    for (final store in [small, whole]) {
      await store.importEntries(entries, useIsolate: false);
      await store.flush();
    }

    expect(small.totalAreaM2, closeTo(whole.totalAreaM2, 1e-6));
    expect(
      sameMasks(
        await decodeAllTiles(smallTiles, FogConfig.baseZoom),
        await decodeAllTiles(wholeTiles, FogConfig.baseZoom),
      ),
      isTrue,
    );
    await small.dispose();
    await whole.dispose();
  });
}
