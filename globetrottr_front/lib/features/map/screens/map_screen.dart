import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/features/map/camera_flight.dart';
import 'package:globetrottr_front/features/map/camera_health.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_locator.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/layers_sheet.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_overlay.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_view_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/player_marker_layer.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';
import 'package:globetrottr_front/features/quests/provider/quest_map_focus.dart';
import 'package:globetrottr_front/features/quests/provider/quest_point_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_point_layer.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_route_layer.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: MapConfig.recenterFlight,
  )..addListener(_fly);
  CameraFlight? _route;
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
    _cameraWatch = _mapController.mapEventStream.listen(_onMapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _answerQuestFocus());
  }

  /// Shows the active quest when the Quests tab asked for it: flies to its
  /// next point, or fits its route, and opens its card.
  void _answerQuestFocus() {
    if (!mounted || !ref.read(questMapFocusProvider)) return;
    ref.read(questMapFocusProvider.notifier).clear();
    final quest = ref.read(activeQuestProvider);
    if (quest == null) return;
    final point = ref.read(questPointProvider);
    final route = [for (final waypoint in quest.waypoints) waypoint.point];
    setState(() => _questOpen = true);
    if (point != null) {
      _flyTo(point.position);
    } else if (route.length > 1) {
      _flight.stop();
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: route,
          padding: MapConfig.questRoutePadding,
        ),
      );
    } else if (route.isNotEmpty) {
      _flyTo(route.first);
    }
  }

  void _onMapEvent(MapEvent event) {
    if (interruptsCameraFlight(event.source)) _flight.stop();
    _logCameraProblem(event);
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

  // Without a position yet, the first fix centres the map (see build).
  Future<void> _recenter() async {
    final position = await ref.read(playerLocatorProvider).locate();
    if (!mounted) return;
    if (position != null) {
      _flyTo(position);
      return;
    }
    final error = ref.read(locationProvider).errorMessage;
    if (error == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(context.localizeErrorMessage(error))),
    );
  }

  void _flyTo(LatLng center) {
    final camera = _mapController.camera;
    final route = CameraFlight(
      from: (center: camera.center, zoom: camera.zoom),
      to: (center: center, zoom: MapConfig.defaultZoom),
    );
    if (route.isStill) return;
    _route = route;
    unawaited(_flight.forward(from: 0));
  }

  void _fly() {
    final view = _route?.at(Curves.easeInOut.transform(_flight.value));
    if (view != null) _mapController.move(view.center, view.zoom);
  }

  @override
  void dispose() {
    _flight.dispose();
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

    final motion = ref.watch(playerMotionProvider);

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
              const MapViewLayer(),
              if (DevConfig.isDevMode) const RecordedPointsLayer(),
              const QuestRouteLayer(),
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
