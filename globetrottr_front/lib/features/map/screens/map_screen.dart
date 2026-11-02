import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/features/map/camera_health.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/layers_sheet.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_overlay.dart';
import 'package:globetrottr_front/features/map/screens/widgets/player_marker_layer.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_point_layer.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _cameraWatch;
  String? _lastCameraProblem;
  bool _questOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationProvider.notifier).startTracking();
      ref.read(questsProvider.notifier).loadQuestsOnce();
    });
    _cameraWatch = _mapController.mapEventStream.listen(_logCameraProblem);
  }

  // Only reports a broken camera; it does not change it.
  void _logCameraProblem(MapEvent event) {
    final problem = describeCameraProblem(event.camera);
    if (problem == _lastCameraProblem) return;
    _lastCameraProblem = problem;
    if (problem != null) {
      debugPrint(
        'CAMERA PROBLEM after ${event.runtimeType} '
        '(${event.source}): $problem',
      );
    }
  }

  void _recenter() {
    final position = ref.read(locationProvider).currentPosition;
    if (position != null) _mapController.move(position, MapConfig.defaultZoom);
  }

  @override
  void dispose() {
    unawaited(_cameraWatch?.cancel());
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrackingState>(locationProvider, (previous, next) {
      if (previous?.currentPosition == null && next.currentPosition != null) {
        _mapController.move(next.currentPosition!, MapConfig.defaultZoom);
      }
    });

    final recording = ref.watch(locationProvider.select((s) => s.isRecording));
    final motion = ref.watch(playerMotionProvider);
    final fog = ref.watch(fogProvider);
    final fogOptions = ref.watch(fogRenderOptionsProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: MapConfig.initialCenter,
              initialZoom: MapConfig.defaultZoom,
              // North stays up, as in the mock-up, which has no compass.
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                enableMultiFingerGestureRace: true,
              ),
            ),
            children: [
              const AppTileLayer(),
              BitmapFogLayer(
                source: fog.value,
                options: fogOptions,
                head: recording ? motion : null,
              ),
              if (DevConfig.isDevMode) const RecordedPointsLayer(),
              ListenableBuilder(
                listenable: motion,
                builder: (context, _) {
                  final position = motion.value;
                  if (position == null) return const SizedBox.shrink();
                  return PlayerMarkerLayer(position: position);
                },
              ),
              QuestPointLayer(
                selected: _questOpen,
                onTap: () => setState(() => _questOpen = true),
              ),
            ],
          ),
          MapOverlay(
            questOpen: _questOpen,
            onQuestToggle: () => setState(() => _questOpen = !_questOpen),
            onLayers: () => showLayersSheet(context),
            onRecenter: _recenter,
          ),
        ],
      ),
    );
  }
}
