import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/map/data/open_free_map_tile_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  const template = 'https://tiles.example/planet/v1/{z}/{x}/{y}.pbf';
  final tileBytes = Uint8List.fromList([1, 2, 3]);

  http.Response tileJson() => http.Response(
    jsonEncode({
      'tiles': [template],
    }),
    200,
  );

  test('resolves the tile URL once for concurrent tiles', () async {
    var tileJsonRequests = 0;
    final tileRequests = <String>[];
    final provider = OpenFreeMapTileProvider(
      client: MockClient((request) async {
        if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
          tileJsonRequests++;
          return tileJson();
        }
        tileRequests.add(request.url.toString());
        return http.Response.bytes(tileBytes, 200);
      }),
    );

    final tiles = await Future.wait<Uint8List>([
      provider.provide(TileIdentity(14, 9148, 5554)),
      provider.provide(TileIdentity(13, 4574, 2777)),
    ]);

    expect(tileJsonRequests, 1);
    expect(tileRequests, [
      'https://tiles.example/planet/v1/14/9148/5554.pbf',
      'https://tiles.example/planet/v1/13/4574/2777.pbf',
    ]);
    expect(tiles.first, tileBytes);
  });

  test('a failed TileJSON request is retried with the next tile', () async {
    var failTileJson = true;
    final provider = OpenFreeMapTileProvider(
      client: MockClient((request) async {
        if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
          return failTileJson ? http.Response('', 500) : tileJson();
        }
        return http.Response.bytes(tileBytes, 200);
      }),
    );

    await expectLater(
      provider.provide(TileIdentity(14, 1, 1)),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.retryable,
          'retryable',
          Retryable.retry,
        ),
      ),
    );
    failTileJson = false;

    expect(await provider.provide(TileIdentity(14, 1, 1)), tileBytes);
  });

  test('a TileJSON without tiles is an error', () async {
    final provider = OpenFreeMapTileProvider(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(
      provider.provide(TileIdentity(14, 1, 1)),
      throwsA(isA<ProviderException>()),
    );
  });

  test('a missing tile is not retried, an unavailable server is', () async {
    var tileStatus = 404;
    final provider = OpenFreeMapTileProvider(
      client: MockClient((request) async {
        if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
          return tileJson();
        }
        return http.Response('', tileStatus);
      }),
    );

    await expectLater(
      provider.provide(TileIdentity(14, 1, 1)),
      throwsA(
        isA<ProviderException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.retryable, 'retryable', Retryable.none),
      ),
    );
    tileStatus = 503;
    await expectLater(
      provider.provide(TileIdentity(14, 1, 1)),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.retryable,
          'retryable',
          Retryable.retry,
        ),
      ),
    );
  });

  test('sends the app user agent', () async {
    final agents = <String?>[];
    final provider = OpenFreeMapTileProvider(
      client: MockClient((request) async {
        agents.add(request.headers['user-agent']);
        if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
          return tileJson();
        }
        return http.Response.bytes(tileBytes, 200);
      }),
    );

    await provider.provide(TileIdentity(14, 1, 1));

    expect(agents, everyElement(MapConfig.tileUserAgentPackageName));
  });

  test('rejects tiles beyond the zoom the server has', () async {
    final provider = OpenFreeMapTileProvider(
      client: MockClient((_) async => tileJson()),
    );

    await expectLater(
      provider.provide(TileIdentity(MapConfig.basemapMaxZoom + 1, 1, 1)),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.retryable,
          'retryable',
          Retryable.none,
        ),
      ),
    );
  });
}
