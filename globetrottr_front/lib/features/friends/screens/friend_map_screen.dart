import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/fog_layer.dart';
import 'package:globetrottr_front/features/fog/provider/friend_fog_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_header.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_loading_overlay.dart';

class FriendMapScreen extends ConsumerStatefulWidget {
  final String friendUsername;

  const FriendMapScreen({super.key, required this.friendUsername});

  @override
  ConsumerState<FriendMapScreen> createState() => _FriendMapScreenState();
}

class _FriendMapScreenState extends ConsumerState<FriendMapScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fogAsyncValue = ref.watch(friendFogProvider(widget.friendUsername));

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
                initialCenter: LatLng(50.0614, 19.9383),
                initialZoom: MapConfig.defaultZoom,
                interactionOptions: InteractionOptions(
                  enableMultiFingerGestureRace: true,
                  rotationThreshold: 10.0,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.globetrottr.app',
                ),
                fogAsyncValue.when(
                  data: (holes) => FogLayer(readyHoles: holes),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) {
                    debugPrint('Error downloading fog: $err');
                    return FogLayer(readyHoles: const []);
                  },
                ),
              ],
            ),
            FriendMapHeader(friendUsername: widget.friendUsername),
            FriendMapLoadingOverlay(isLoading: fogAsyncValue.isLoading),
          ],
        ),
      ),
    );
  }
}
