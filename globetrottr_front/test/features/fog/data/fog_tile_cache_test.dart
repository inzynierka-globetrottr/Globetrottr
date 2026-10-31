import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_tile_cache.dart';

import '../../../support/in_memory_fog_tile_storage.dart';

void main() {
  const tile = FogTileId(15, 1, 2);
  late FogTileCache cache;

  setUp(() {
    cache = FogTileCache(InMemoryFogTileStorage(), maxTiles: 4);
  });

  group('withPinned', () {
    test('pins the tiles while the action runs', () async {
      var pinned = false;

      await cache.withPinned({tile}, () async {
        pinned = cache.pinned.contains(tile);
      });

      expect(pinned, isTrue);
      expect(cache.pinned, isEmpty);
    });

    test('hands back the result of the action', () async {
      expect(await cache.withPinned({tile}, () async => 7), 7);
    });

    test('releases the tiles when the action fails', () async {
      await expectLater(
        cache.withPinned({tile}, () async => throw StateError('failed')),
        throwsStateError,
      );

      expect(cache.pinned, isEmpty);
    });
  });
}
