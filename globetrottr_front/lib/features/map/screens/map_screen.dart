import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/tracking_state.dart';
import 'package:globetrottr_front/features/map/screens/widgets/compass_button.dart';
import 'package:globetrottr_front/features/map/screens/widgets/fog_layer.dart';
import 'package:globetrottr_front/features/map/screens/widgets/player_marker.dart';
import 'package:globetrottr_front/features/map/screens/widgets/recenter_button.dart';
import 'package:globetrottr_front/features/map/screens/widgets/recording_toggle_button.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).startTracking();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrackingState>(locationProvider, (previous, next) {
      if (previous?.currentPosition == null && next.currentPosition != null) {
        _mapController.move(next.currentPosition!, 16.0);
      }
    });

    final locationState = ref.watch(locationProvider);

    final position = locationState.currentPosition;
    final isRecording = locationState.isRecording;
    final discoveredPoints = locationState.discoveredPoints;

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(baseColor: AppColors.background),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(
                  50.0614,
                  19.9383,
                ), // * for now hardcoded to Kraków
                initialZoom: 14.0,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 10.0,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      //TODO: change styling, temporarily changed for better fog visibility
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.globetrottr.app',
                ),

                // displays fog and punches a hole in it around the player position, if recording is active
                // here for debug purposes, I am not sure if it will stay like this
                FogLayer(
                  playerPosition: isRecording ? position : null,
                  discoveredPoints: discoveredPoints,
                  visionRadiusInMeters: MapConfig.defaultVisionRadius,
                ),
                if (position != null)
                  // think about moving this to a separate widget too, but im not sure
                  // Marcel here, yes, I think you should move this to a separate widget, just like the buttons
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 20,
                        height: 20,
                        child: const PlayerMarker(),
                      ),
                    ],
                  ),
              ],
            ),

            // this is temporary, until we get more widgets on screen and fully figure out the layout
            Positioned(
              top: 50.0,
              right: 16.0,
              child: CompassButton(mapController: _mapController),
            ),

            Positioned(
              top: 110.0,
              right: 16.0,
              child: RecenterButton(mapController: _mapController),
            ),

            Positioned(
              top: 170.0,
              right: 16.0,
              child: const RecordingToggleButton(),
            ),
          ],
        ),
      ),
    );
  }
}
