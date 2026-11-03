import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/map_stats_provider.dart';

/// The pill at the top of the map: how much of the district is discovered,
/// the new ground of the current walk while recording, and the button that
/// starts or stops the walk.
class MapStatusPill extends ConsumerWidget {
  const MapStatusPill({super.key});

  static const _height = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final recording = ref.watch(locationProvider.select((s) => s.isRecording));
    final progress = ref.watch(areaProgressProvider);
    final newArea = ref.watch(sessionNewAreaProvider);

    return NeuSurface(
      shadows: context.shadows.mapControl,
      borderRadius: BorderRadius.circular(_height / 2),
      height: _height,
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: _Stat(
              value: l10n.mapPercent(formatPercent(progress.share)),
              label: progress.regionName ?? l10n.mapUnknownRegion,
            ),
          ),
          if (recording) ...[
            const NeuDivider.vertical(length: 30),
            Expanded(
              child: _Stat(
                value: l10n.mapNewArea(formatKm2(newArea, locale)),
                label: l10n.mapNewAreaLabel,
                accent: true,
              ),
            ),
          ],
          _RecordButton(recording: recording),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent = false});

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          style: typography.value.copyWith(
            height: 1.2,
            color: accent ? context.palette.accent : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.small,
        ),
      ],
    );
  }
}

class _RecordButton extends ConsumerWidget {
  const _RecordButton({required this.recording});

  final bool recording;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(locationProvider.notifier);
    if (recording) return notifier.setRecording(false);
    if (await notifier.startRecording() || !context.mounted) return;
    final reason = ref.read(locationProvider).errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(context.localizeErrorMessage(reason))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return NeuIconButton(
      size: 52,
      fill: recording ? NeuFill.danger : NeuFill.accent,
      semanticLabel: recording ? l10n.mapStopWalk : l10n.mapStartWalk,
      onPressed: () => _toggle(context, ref),
      child: recording
          ? const AppIcon(AppIcons.stop, size: 15)
          : const Padding(
              // The triangle looks centred a little to the right.
              padding: EdgeInsets.only(left: 3),
              child: AppIcon(AppIcons.play, size: 19),
            ),
    );
  }
}
