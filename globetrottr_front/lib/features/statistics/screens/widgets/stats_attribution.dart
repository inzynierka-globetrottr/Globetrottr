import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// Credits the boundary data (ODbL) under the screens that use it.
class StatsAttribution extends StatelessWidget {
  const StatsAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.regionsAttribution,
      textAlign: TextAlign.center,
      style: context.typography.small.copyWith(
        color: context.palette.textMuted,
      ),
    );
  }
}
