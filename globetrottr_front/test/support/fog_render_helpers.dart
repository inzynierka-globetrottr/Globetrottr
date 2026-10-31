import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/features/fog/bitmap/fog_scale.dart';
import 'package:globetrottr_front/features/fog/data/store/fog_store.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_painter.dart';
import 'package:globetrottr_front/features/fog/render/fog_tile_source.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';

import 'fog_test_helpers.dart';
import 'in_memory_fog_tile_storage.dart';

const Size viewSize = Size(400, 800);

MapCamera cameraAt({
  double? zoom,
  double rotation = 0,
  double lat = krakowLat,
  double lng = krakowLng,
}) {
  return MapCamera(
    crs: const Epsg3857(),
    center: LatLng(lat, lng),
    zoom: zoom ?? FogConfig.baseZoom.toDouble(),
    rotation: rotation,
    nonRotatedSize: const math.Point<double>(400, 800),
  );
}

Future<FogStore> openStore({
  FogTileStorage? storage,
  int maxCachedTiles = 256,
}) {
  return FogStore.open(
    storage ?? InMemoryFogTileStorage(),
    maxCachedTiles: maxCachedTiles,
    flushDelay: const Duration(hours: 1),
  );
}

Future<void> walk(
  FogStore store,
  String session, {
  int points = 40,
  double stepMeters = 10,
  double startLat = krakowLat,
  double startLng = krakowLng,
  double north = 0,
}) async {
  for (var i = 0; i < points; i++) {
    final at = offsetMeters(
      startLat,
      startLng,
      east: i * stepMeters * (1 - north),
      north: i * stepMeters * north,
    );
    await store.applyPoint(
      sessionId: session,
      latitude: at.lat,
      longitude: at.lng,
    );
  }
}

/// Screen alpha lookup after painting [painter] on a 400x800 canvas.
Future<int Function(int x, int y)> renderAlpha(CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), viewSize);
  final image = await recorder.endRecording().toImage(400, 800);
  final bytes = (await image.toByteData())!;
  return (int x, int y) => bytes.getUint8((y * 400 + x) * 4 + 3);
}

Offset screenOf(MapCamera camera, double lat, double lng) {
  final p = camera.latLngToScreenPoint(LatLng(lat, lng));
  return Offset(p.x, p.y);
}

Future<FogTileSource> readySource(FogStore store, MapCamera camera) async {
  final source = FogTileSource(store);
  source.ensureVisible(camera);
  await source.whenIdle();
  return source;
}

BitmapFogPainter painterFor(
  MapCamera camera, {
  FogTileSource? source,
  LatLng? head,
  bool softEdge = false,
}) {
  return BitmapFogPainter(
    camera: camera,
    source: source,
    head: head == null ? null : ValueNotifier<LatLng?>(head),
    options: BitmapFogPainter.defaultOptions.copyWith(softEdge: softEdge),
  );
}

/// Radius of the vision disc in pixels of the base level, at Krakow.
double get baseRadiusPixels => metersToPixels(
  meters: FogConfig.visionRadiusMeters,
  latitude: krakowLat,
  zoom: FogConfig.baseZoom.toDouble(),
);
