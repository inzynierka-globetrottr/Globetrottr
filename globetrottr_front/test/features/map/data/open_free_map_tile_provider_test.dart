import 'dart:async';
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

  test('a TileJSON that is not JSON, like a captive portal page, is a '
      'retryable error', () async {
    for (final body in ['<html>Log in to the Wi-Fi</html>', '[]']) {
      final provider = OpenFreeMapTileProvider(
        client: MockClient((_) async => http.Response(body, 200)),
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
        reason: body,
      );
    }
  });

  test('a request that hangs fails after the timeout and is retried', () async {
    var hang = true;
    final provider = OpenFreeMapTileProvider(
      requestTimeout: const Duration(milliseconds: 20),
      client: MockClient((request) {
        if (hang) return Completer<http.Response>().future;
        if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
          return Future.value(tileJson());
        }
        return Future.value(http.Response.bytes(tileBytes, 200));
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
    hang = false;

    expect(await provider.provide(TileIdentity(14, 1, 1)), tileBytes);
  });

  group('data release', () {
    late DateTime now;
    late String currentTemplate;
    late bool tileJsonDown;
    late int tileJsonRequests;
    late List<String> tileRequests;
    late OpenFreeMapTileProvider provider;

    setUp(() {
      now = DateTime(2026, 11, 3, 8);
      currentTemplate = template;
      tileJsonDown = false;
      tileJsonRequests = 0;
      tileRequests = [];
      provider = OpenFreeMapTileProvider(
        clock: () => now,
        client: MockClient((request) async {
          if (request.url.toString() == MapConfig.basemapTileJsonUrl) {
            tileJsonRequests++;
            if (tileJsonDown) return http.Response('', 503);
            return http.Response(
              jsonEncode({
                'tiles': [currentTemplate],
              }),
              200,
            );
          }
          tileRequests.add(request.url.toString());
          return http.Response.bytes(tileBytes, 200);
        }),
      );
    });

    test('the tile URL is kept while it is fresh', () async {
      await provider.provide(TileIdentity(14, 1, 1));
      now = now.add(
        MapConfig.basemapTileJsonMaxAge - const Duration(minutes: 1),
      );
      await provider.provide(TileIdentity(14, 1, 2));

      expect(tileJsonRequests, 1);
    });

    test('an old tile URL is read again, so a removed release is not used '
        'for the whole session', () async {
      await provider.provide(TileIdentity(14, 1, 1));
      currentTemplate = 'https://tiles.example/planet/v2/{z}/{x}/{y}.pbf';
      now = now.add(MapConfig.basemapTileJsonMaxAge);
      await provider.provide(TileIdentity(14, 1, 2));

      expect(tileJsonRequests, 2);
      expect(tileRequests.last, 'https://tiles.example/planet/v2/14/1/2.pbf');
    });

    test('a failed refresh keeps the old tile URL and waits before the next '
        'attempt', () async {
      await provider.provide(TileIdentity(14, 1, 1));
      tileJsonDown = true;
      now = now.add(MapConfig.basemapTileJsonMaxAge);

      expect(await provider.provide(TileIdentity(14, 1, 2)), tileBytes);
      expect(await provider.provide(TileIdentity(14, 1, 3)), tileBytes);
      expect(tileJsonRequests, 2);
      expect(tileRequests.last, 'https://tiles.example/planet/v1/14/1/3.pbf');

      tileJsonDown = false;
      currentTemplate = 'https://tiles.example/planet/v2/{z}/{x}/{y}.pbf';
      now = now.add(MapConfig.basemapTileJsonRetryDelay);
      await provider.provide(TileIdentity(14, 1, 4));

      expect(tileJsonRequests, 3);
      expect(tileRequests.last, 'https://tiles.example/planet/v2/14/1/4.pbf');
    });
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
