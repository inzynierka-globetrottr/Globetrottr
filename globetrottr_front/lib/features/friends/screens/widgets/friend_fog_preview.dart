import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/features/fog/fog_layer.dart';
import 'package:globetrottr_front/features/fog/provider/friend_fog_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/fog_camera_fit.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/friend_map_panel.dart';
import 'package:globetrottr_front/features/map/screens/widgets/app_tile_layer.dart';
import 'package:go_router/go_router.dart';

/// A still map of the friend's discovered area, framed to fit it, with a
/// button that opens the friend's map on the full screen in [mapView].
class FriendFogPreview extends ConsumerWidget {
  const FriendFogPreview({
    super.key,
    required this.username,
    this.mapView = FriendMapView.theirs,
  });

  final String username;
  final FriendMapView mapView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // TODO(fog): draw the friend's fog with BitmapFogLayer and a remote tile
    // source; on the comparison also the own fog.
    final holes = ref.watch(friendFogProvider(username)).value ?? const [];
    final revision = identityHashCode(holes);
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          image: true,
          label: l10n.profileFogMap(username),
          child: ExcludeSemantics(
            child: FlutterMap(
              // The camera is fitted only when the map is created.
              key: ValueKey(revision),
              options: MapOptions(
                initialCenter: MapConfig.initialCenter,
                initialZoom: MapConfig.defaultZoom,
                initialCameraFit: fogCameraFit(holes),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const AppTileLayer(),
                FogLayer(readyHoles: holes, holesRevision: revision),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: NeuIconButton(
            size: 40,
            overMap: true,
            semanticLabel: l10n.profileOpenMap,
            onPressed: () =>
                context.go('/friends/$username/map?view=${mapView.name}'),
            child: const AppIcon(AppIcons.expand, size: 20),
          ),
        ),
      ],
    );
  }
}
