import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/features/quests/provider/quest_point_provider.dart';

/// The next point of the active quest on the map; tapping it opens the
/// quest card, and while the card is open the point is ringed.
class QuestPointLayer extends ConsumerWidget {
  const QuestPointLayer({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  static const _box = Size(120, 100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = ref.watch(questPointProvider);
    if (point == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: point.position,
          width: _box.width,
          height: _box.height,
          child: _QuestPin(point: point, selected: selected, onTap: onTap),
        ),
      ],
    );
  }
}

class _QuestPin extends StatelessWidget {
  const _QuestPin({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final QuestPoint point;
  final bool selected;
  final VoidCallback onTap;

  static const _diameter = 34.0;
  static const _border = 3.0;
  static const _selectionRing = 3.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    final distance = formatDistance(
      point.distanceMeters,
      Localizations.localeOf(context).toString(),
    );
    final label = context.l10n.questPointLabel(distance);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: _diameter + 2 * _border,
              height: _diameter + 2 * _border,
              decoration: BoxDecoration(
                color: palette.gold,
                shape: BoxShape.circle,
                border: Border.all(color: palette.onAccent, width: _border),
                boxShadow: [
                  for (final s in shadows.marker) s.toBoxShadow(),
                  if (selected)
                    BoxShadow(
                      color: palette.accent,
                      spreadRadius: _selectionRing,
                    ),
                ],
              ),
              child: Center(
                child: AppIcon(AppIcons.flag, size: 20, color: palette.text),
              ),
            ),
          ),
        ),
        Positioned(
          top: _QuestPinLabel.offset,
          // The pin above already says it to screen readers.
          child: ExcludeSemantics(child: _QuestPinLabel(text: label)),
        ),
      ],
    );
  }
}

class _QuestPinLabel extends StatelessWidget {
  const _QuestPinLabel({required this.text});

  final String text;

  /// From the top of the marker box to the label, under the pin.
  static const offset = 76.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.palette.background,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [for (final s in context.shadows.mapLabel) s.toBoxShadow()],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(text, style: context.typography.captionStrong),
    ),
  );
}
