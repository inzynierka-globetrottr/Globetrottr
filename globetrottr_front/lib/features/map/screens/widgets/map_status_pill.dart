import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/animated_number.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/map_stats_provider.dart';

/// The pill at the top of the map, fed by the providers; the button starts
/// or stops the walk.
class MapStatusPill extends ConsumerWidget {
  const MapStatusPill({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(locationProvider.notifier);
    if (ref.read(locationProvider).isRecording) {
      return notifier.setRecording(false);
    }
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
    final progress = ref.watch(areaProgressProvider);
    return MapStatusPillView(
      share: progress.share,
      regionName: progress.regionName,
      newArea: ref.watch(sessionNewAreaProvider),
      recording: ref.watch(locationProvider.select((s) => s.isRecording)),
      onRecord: () => _toggle(context, ref),
    );
  }
}

/// How much of the district is discovered and, while recording, the new
/// ground of the walk, which unfolds next to it when the walk starts.
class MapStatusPillView extends StatelessWidget {
  const MapStatusPillView({
    super.key,
    required this.share,
    required this.regionName,
    required this.newArea,
    required this.recording,
    required this.onRecord,
  });

  final double? share;
  final String? regionName;
  final double? newArea;
  final bool recording;
  final VoidCallback onRecord;

  static const _height = 64.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final motion = context.motion;
    final locale = Localizations.localeOf(context).toString();
    final district = _Stat(
      value: share,
      format: (share) => l10n.mapPercent(formatPercent(share)),
      label: regionName ?? l10n.mapUnknownRegion,
    );
    final walk = Row(
      children: [
        const SizedBox(width: _gap),
        const NeuDivider.vertical(length: 30),
        const SizedBox(width: _gap),
        Expanded(
          child: _Stat(
            value: newArea,
            format: (area) => l10n.mapNewArea(formatKm2(area, locale)),
            label: l10n.mapNewAreaLabel,
            accent: true,
          ),
        ),
      ],
    );

    return NeuSurface(
      shadows: context.shadows.mapControl,
      borderRadius: BorderRadius.circular(_height / 2),
      height: _height,
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.maxWidth - _RecordButton.size - _gap;
          return TweenAnimationBuilder<double>(
            tween: Tween(end: recording ? 1 : 0),
            duration: motion.long,
            curve: motion.curve,
            builder: (context, open, _) {
              final walkWidth = room / 2 * open;
              return Row(
                children: [
                  SizedBox(width: room - walkWidth, child: district),
                  if (open > 0)
                    SizedBox(
                      width: walkWidth,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: room / 2,
                          maxWidth: room / 2,
                          child: Opacity(opacity: open, child: walk),
                        ),
                      ),
                    ),
                  const SizedBox(width: _gap),
                  _RecordButton(recording: recording, onPressed: onRecord),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.format,
    required this.label,
    this.accent = false,
  });

  final double? value;
  final String Function(double? value) format;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedNumber(
          value: value,
          format: format,
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

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.recording, required this.onPressed});

  final bool recording;
  final VoidCallback onPressed;

  static const size = 52.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final motion = context.motion;
    return NeuIconButton(
      size: size,
      fill: recording ? NeuFill.danger : NeuFill.accent,
      semanticLabel: recording ? l10n.mapStopWalk : l10n.mapStartWalk,
      onPressed: onPressed,
      child: AnimatedSwitcher(
        duration: motion.short,
        switchInCurve: motion.curve,
        switchOutCurve: motion.curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: recording
            ? const AppIcon(AppIcons.stop, key: ValueKey('stop'), size: 15)
            : const Padding(
                key: ValueKey('play'),
                // The triangle looks centred a little to the right.
                padding: EdgeInsets.only(left: 3),
                child: AppIcon(AppIcons.play, size: 19),
              ),
      ),
    );
  }
}
