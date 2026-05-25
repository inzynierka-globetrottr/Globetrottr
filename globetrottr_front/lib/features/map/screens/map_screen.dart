import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/features/map/screens/widgets/compass_button.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(
        baseColor: AppColors.background
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(50.0614, 19.9383),
                initialZoom: 14.0,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 10.0,
                )
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.globetrottr.app',
                ),
              ],
            ),

            Positioned(
              top: 50.0, // Safely drops it below the status bar notch
              right: 16.0,
              child: CompassButton(mapController: _mapController),
            ),
          ]
        )
      )
    );
  }
}