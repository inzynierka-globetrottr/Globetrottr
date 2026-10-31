import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/debug/recorded_points_source.dart';
import 'package:globetrottr_front/features/fog/render/fog_camera.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:latlong2/latlong.dart';

class RecordedPointsVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // The state is the switch itself, so a setter reads best at the call site.
  // ignore: use_setters_to_change_properties
  void set({required bool visible}) => state = visible;
}

/// Whether the map shows the points that are really stored in the track log.
final recordedPointsVisibleProvider =
    NotifierProvider<RecordedPointsVisibleNotifier, bool>(
      RecordedPointsVisibleNotifier.new,
    );

/// Draws every GPS fix stored in the track log as a dot and joins the fixes
/// that follow each other in a session with a thin line. Whatever the fog
/// reveals between these dots is interpolation.
class RecordedPointsPainter extends CustomPainter {
  RecordedPointsPainter(this.camera, this.source) : super(repaint: source);

  static const Color dotColor = Color(0xFFFF2D95);
  static const Color lineColor = Color(0xFF00E5FF);
  static const double dotSize = 6;

  final MapCamera camera;
  final RecordedPointsSource source;

  @override
  void paint(Canvas canvas, Size size) {
    if (!camera.isUsableForFog) return;
    final points = source.points;
    if (points.isEmpty) return;

    final screen = <Offset>[];
    final lines = ui.Path();
    for (var i = 0; i < points.length; i++) {
      final p = camera.latLngToScreenPoint(
        LatLng(points[i].latitude, points[i].longitude),
      );
      screen.add(Offset(p.x, p.y));
    }

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final neighbours =
          previous.sessionId == current.sessionId &&
          previous.id != null &&
          current.id == previous.id! + 1;
      if (!neighbours) continue;
      lines
        ..moveTo(screen[i - 1].dx, screen[i - 1].dy)
        ..lineTo(screen[i].dx, screen[i].dy);
    }

    canvas
      ..drawPath(
        lines,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = lineColor.withValues(alpha: 0.8),
      )
      ..drawPoints(
        ui.PointMode.points,
        [
          for (final offset in screen)
            if (offset.dx > -dotSize &&
                offset.dx < size.width + dotSize &&
                offset.dy > -dotSize &&
                offset.dy < size.height + dotSize)
              offset,
        ],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = dotSize
          ..color = dotColor,
      );
  }

  @override
  bool shouldRepaint(covariant RecordedPointsPainter oldDelegate) {
    return oldDelegate.source != source ||
        oldDelegate.camera.center != camera.center ||
        oldDelegate.camera.zoom != camera.zoom ||
        oldDelegate.camera.rotation != camera.rotation;
  }
}

/// Place among the children of a `FlutterMap`. Draws nothing until the
/// developer switches it on.
class RecordedPointsLayer extends ConsumerStatefulWidget {
  const RecordedPointsLayer({super.key});

  @override
  ConsumerState<RecordedPointsLayer> createState() =>
      _RecordedPointsLayerState();
}

class _RecordedPointsLayerState extends ConsumerState<RecordedPointsLayer> {
  late final RecordedPointsSource _source;
  StreamSubscription<dynamic>? _logged;

  @override
  void initState() {
    super.initState();
    _source = RecordedPointsSource(ref.read(trackLogStorageProvider));
    _logged = ref
        .read(locationServiceProvider)
        .loggedPoints
        .listen(_source.add);
  }

  @override
  void dispose() {
    unawaited(_logged?.cancel());
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(recordedPointsVisibleProvider)) {
      _source.clear();
      return const SizedBox.shrink();
    }
    final camera = MapCamera.of(context);
    unawaited(_source.ensure(camera));
    return SizedBox.expand(
      child: IgnorePointer(
        child: CustomPaint(painter: RecordedPointsPainter(camera, _source)),
      ),
    );
  }
}
