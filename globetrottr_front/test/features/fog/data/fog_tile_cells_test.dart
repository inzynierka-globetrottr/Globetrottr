import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_cell_areas.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_mask.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_codec.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_tile_id.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_cells.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';

import '../../../support/in_memory_fog_tile_storage.dart';

void main() {
  test('stored tiles are read back as cell areas', () async {
    const id = FogTileId(15, 18199, 11116);
    final mask = FogMask();
    for (var y = 48; y < 64; y++) {
      for (var x = 32; x < 48; x++) {
        mask.data[y * FogTileId.size + x] = 255;
      }
    }
    final encoded = FogTileCodec.encode(mask);
    final storage = InMemoryFogTileStorage();
    await storage.commit(
      upserts: [
        StoredFogTile(
          id: id,
          flag: encoded.flag,
          rev: 1,
          areaM2: 1,
          bytes: encoded.bytes,
        ),
      ],
      meta: const {},
    );

    final cells = await loadCellAreas(storage, [id]);

    final values = cells[id]!.values;
    expect(values[3 * FogCellAreas.side + 2], greaterThan(0));
    expect(
      cells[id]!.total,
      closeTo(256 * FogCellAreas.pixelAreaM2(id), 1e-3),
    );
  });
}
