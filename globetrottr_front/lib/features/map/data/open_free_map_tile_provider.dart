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
///
/// OpenFreeMap removes old releases, so the URL is read again once it is
/// [MapConfig.basemapTileJsonMaxAge] old; if that fails, the old URL stays in
/// use until a later attempt succeeds.
///
/// Our own provider rather than `NetworkVectorTileProvider`, which takes a
/// fixed URL, opens a new client for every tile and has no timeout.
class OpenFreeMapTileProvider extends VectorTileProvider {
  OpenFreeMapTileProvider({
    required this._client,
    this._requestTimeout = MapConfig.basemapRequestTimeout,
    DateTime Function() clock = DateTime.now,
  }) : _now = clock;

  final http.Client _client;
  final Duration _requestTimeout;
  final DateTime Function() _now;

  String? _template;
  DateTime? _refreshAt;
  Future<String>? _fetching;

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
    final stale = _template;
    final refreshAt = _refreshAt;
    if (stale != null && refreshAt != null && _now().isBefore(refreshAt)) {
      return stale;
    }
    final fetching = _fetching ??= _fetchTemplate();
    try {
      final template = await fetching;
      _template = template;
      _refreshAt = _now().add(MapConfig.basemapTileJsonMaxAge);
      return template;
    } on Object {
      if (stale == null) rethrow;
      _refreshAt = _now().add(MapConfig.basemapTileJsonRetryDelay);
      return stale;
    } finally {
      if (identical(_fetching, fetching)) _fetching = null;
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
    // A captive portal answers with its own page, so the body may be anything;
    // the next try may get through.
    final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw ProviderException(
        message: 'TileJSON is not JSON',
        retryable: Retryable.retry,
      );
    }
    final tiles = json is Map ? json['tiles'] : null;
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
      return await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw ProviderException(message: e.message, retryable: Retryable.retry);
    } on TimeoutException {
      throw ProviderException(
        message: 'No response within $_requestTimeout: $url',
        retryable: Retryable.retry,
      );
    }
  }

  static bool _isRetryable(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;
}
