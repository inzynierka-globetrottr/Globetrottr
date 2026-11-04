import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/features/fog/fog_layer.dart';
import 'package:globetrottr_front/features/fog/provider/friend_fog_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/fog_camera_fit.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_fog_error_notice.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_header.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_loading_overlay.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_panel.dart';

export 'package:globetrottr_front/features/friends/screens/widgets/friend_map_panel.dart'
    show FriendMapView;

/// The friend's fog on the full screen, alone or together with the user's.
class FriendMapScreen extends ConsumerStatefulWidget {
  final String friendUsername;
  final FriendMapView initialView;

  const FriendMapScreen({
    super.key,
    required this.friendUsername,
    this.initialView = FriendMapView.theirs,
  });

  @override
  ConsumerState<FriendMapScreen> createState() => _FriendMapScreenState();
}

class _FriendMapScreenState extends ConsumerState<FriendMapScreen> {
  static const _side = 16.0;

  /// Keeps the friend's area clear of the header and the panel.
  static const _fitPadding = EdgeInsets.fromLTRB(32, 120, 32, 200);

  final MapController _mapController = MapController();
  late FriendMapView _view = widget.initialView;

  /// The fog may already be loaded by the profile's preview.
  late final CameraFit? _initialFit = fogCameraFit(
    ref.read(friendFogProvider(widget.friendUsername)).value ?? const [],
    padding: _fitPadding,
  );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fog = friendFogProvider(widget.friendUsername);
    ref.listen(fog, (previous, next) {
      if (previous?.value == next.value) return;
      final fit = fogCameraFit(next.value ?? const [], padding: _fitPadding);
      if (fit != null) _mapController.fitCamera(fit);
    });
    final fogAsyncValue = ref.watch(fog);
    final safe = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: MapConfig.initialCenter,
              initialZoom: MapConfig.defaultZoom,
              initialCameraFit: _initialFit,
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                rotationThreshold: 10.0,
              ),
            ),
            children: [
              const AppTileLayer(),
              // TODO(fog): draw the friend's fog with BitmapFogLayer and a
              // remote tile source; together with the own fog in the
              // "together" view.
              fogAsyncValue.when(
                data: (holes) => FogLayer(
                  readyHoles: holes,
                  holesRevision: identityHashCode(holes),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) {
                  debugPrint('Error downloading fog: $err');
                  return const FogLayer(readyHoles: [], holesRevision: 0);
                },
              ),
            ],
          ),
          Positioned(
            top: safe.top + 16,
            left: _side + 4,
            right: _side + 4,
            child: FriendMapHeader(friendUsername: widget.friendUsername),
          ),
          Positioned(
            left: _side,
            right: _side,
            bottom: safe.bottom + 24,
            child: FriendMapPanel(
              username: widget.friendUsername,
              view: _view,
              onView: (view) => setState(() => _view = view),
            ),
          ),
          FriendMapLoadingOverlay(isLoading: fogAsyncValue.isLoading),
          if (fogAsyncValue.hasError && !fogAsyncValue.isLoading)
            const FriendFogErrorNotice(),
        ],
      ),
    );
  }
}
