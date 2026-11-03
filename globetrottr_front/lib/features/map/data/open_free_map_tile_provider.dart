import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:http/http.dart' as http;
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// The base map tiles for the whole app; null leaves the map without a base
/// map, which widget tests use so nothing is requested from the network.
final basemapTileProvider = Provider<VectorTileProvider?>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenFreeMapTileProvider(client: client);
});

/// The tile URL carries the data release and is read from the TileJSON when
/// the first tile is needed, so an app that starts offline needs no request
/// until a tile is missing from the cache (the cache keys tiles by position,
/// not by URL). A failed TileJSON request is repeated with the next tile.
class OpenFreeMapTileProvider extends VectorTileProvider {
  OpenFreeMapTileProvider({required this._client});

  final http.Client _client;
  Future<String>? _template;

  static const _headers = {'User-Agent': MapConfig.tileUserAgentPackageName};

  @override
  int get maximumZoom => MapConfig.basemapMaxZoom;

  @override
  int get minimumZoom => 0;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    if (tile.z > maximumZoom || tile.z < minimumZoom || !tile.isValid()) {
      throw ProviderException(
        message: 'Invalid tile coordinates $tile',
        retryable: Retryable.none,
        statusCode: 400,
      );
    }
    final template = await _resolveTemplate();
    final url = template
        .replaceAll('{z}', '${tile.z}')
        .replaceAll('{x}', '${tile.x}')
        .replaceAll('{y}', '${tile.y}');
    final response = await _get(url);
    if (response.statusCode == 200) return response.bodyBytes;
    throw ProviderException(
      message: 'Cannot retrieve tile: HTTP ${response.statusCode}: $url',
      statusCode: response.statusCode,
      retryable: _isRetryable(response.statusCode)
          ? Retryable.retry
          : Retryable.none,
    );
  }

  Future<String> _resolveTemplate() async {
    final pending = _template ??= _fetchTemplate();
    try {
      return await pending;
    } on Object {
      if (identical(_template, pending)) _template = null;
      rethrow;
    }
  }

  Future<String> _fetchTemplate() async {
    final response = await _get(MapConfig.basemapTileJsonUrl);
    if (response.statusCode != 200) {
      throw ProviderException(
        message: 'Cannot read TileJSON: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        retryable: Retryable.retry,
      );
    }
    final tiles = (jsonDecode(response.body) as Map<String, dynamic>)['tiles'];
    if (tiles is! List || tiles.isEmpty || tiles.first is! String) {
      throw ProviderException(
        message: 'TileJSON names no tiles',
        retryable: Retryable.retry,
      );
    }
    return tiles.first as String;
  }

  Future<http.Response> _get(String url) async {
    try {
      return await _client.get(Uri.parse(url), headers: _headers);
    } on http.ClientException catch (e) {
      throw ProviderException(message: e.message, retryable: Retryable.retry);
    }
  }

  static bool _isRetryable(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;
}
