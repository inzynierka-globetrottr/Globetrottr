import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_range.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';

import '../../../support/in_memory_fog_tile_storage.dart';

class _FailingRangeStorage extends InMemoryFogTileStorage {
  int calls = 0;

  @override
  Future<List<StoredFogTile>> loadRange({
    required int z,
    required int xMin,
    required int xMax,
    required int yMin,
    required int yMax,
  }) async {
    calls++;
    if (calls == 1) throw StateError('the read failed');
    return super.loadRange(
      z: z,
      xMin: xMin,
      xMax: xMax,
      yMin: yMin,
      yMax: yMax,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a failed load is not fatal and the range is tried again', () async {
    final storage = _FailingRangeStorage();
    final store = await FogStore.open(storage);
    final source = FogTileSource(store);
    addTearDown(store.dispose);
    addTearDown(source.dispose);
    const range = FogTileRange(z: 15, xMin: 1, xMax: 1, yMin: 2, yMax: 2);

    source.ensureRange(range);
    await source.whenIdle();
    source.ensureRange(range);
    await source.whenIdle();

    expect(storage.calls, 2);
    expect(store.isKnownAbsent(const FogTileId(15, 1, 2)), isTrue);
  });
}
