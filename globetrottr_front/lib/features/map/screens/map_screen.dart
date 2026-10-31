import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/features/map/camera_health.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/debug/widgets/dev_floating_button.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/player_motion.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/compass_button.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/fog/render/bitmap_fog_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/player_marker_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/recenter_button.dart';
import 'package:globetrottr_front/features/map/screens/widgets/recording_toggle_button.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_drawer.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _cameraWatch;
  String? _lastCameraProblem;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(locationProvider.notifier).startTracking());
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
    final topSafeInset = MediaQuery.paddingOf(context).top;

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(baseColor: AppColors.background),
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const QuestDrawer(),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: MapConfig.initialCenter,
                initialZoom: MapConfig.defaultZoom,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 10.0,
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
              ],
            ),

            Positioned(
              top: topSafeInset + 16.0,
              left: 16.0,
              child: Builder(
                builder: (context) {
                  return NeuIconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: const Icon(
                      Icons.menu_rounded,
                      color: AppColors.text,
                      size: 22,
                    ),
                  );
                },
              ),
            ),

            if (DevConfig.isDevMode)
              Positioned(
                top: topSafeInset + 76.0,
                left: 16.0,
                child: const DevFloatingButton(heroTag: 'map_dev_fab'),
              ),

            Positioned(
              top: topSafeInset + 16.0,
              right: 16.0,
              child: const RecordingToggleButton(),
            ),
            Positioned(
              top: topSafeInset + 76.0,
              right: 16.0,
              child: RecenterButton(mapController: _mapController),
            ),
            Positioned(
              top: topSafeInset + 136.0,
              right: 16.0,
              child: CompassButton(mapController: _mapController),
            ),

            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NeuBottomNavbar(activeItem: NavbarItem.map),
            ),
          ],
        ),
      ),
    );
  }
}
