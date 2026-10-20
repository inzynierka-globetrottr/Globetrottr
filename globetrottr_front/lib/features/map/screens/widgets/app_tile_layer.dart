import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: MapConfig.tileUrlTemplate,
      subdomains: MapConfig.tileSubdomains,
      userAgentPackageName: MapConfig.tileUserAgentPackageName,
    );
  }
}
