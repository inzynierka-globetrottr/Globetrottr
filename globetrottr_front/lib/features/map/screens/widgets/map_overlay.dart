import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/debug/widgets/dev_floating_button.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_controls.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_status_pill.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_flag.dart';
import 'package:go_router/go_router.dart';

/// Everything floating over the map. Taps between the elements reach the
/// map.
class MapOverlay extends ConsumerWidget {
  const MapOverlay({
    super.key,
    required this.questOpen,
    required this.onQuestToggle,
    required this.onLayers,
    required this.onRecenter,
  });

  final bool questOpen;
  final VoidCallback onQuestToggle;
  final VoidCallback onLayers;
  final VoidCallback onRecenter;

  static const _margin = 16.0;
  static const _top = 5.0;

  /// The pill and the quest card stop short of the button column.
  static const _rightOfColumn = _margin + MapControls.width + _margin;

  /// The quest flag sits under the pill.
  static const _questTop = _top + 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final quest = ref.watch(activeQuestProvider);
    final devTop =
        (quest == null ? _questTop : _questTop + QuestFlag.size) + _margin;

    return Stack(
      children: [
        Positioned(
          top: top + _top,
          left: _margin,
          right: _rightOfColumn,
          child: const MapStatusPill(),
        ),
        Positioned(
          top: top + _top,
          right: _margin,
          child: MapControls(onLayers: onLayers, onRecenter: onRecenter),
        ),
        if (quest != null)
          Positioned(
            top: top + _questTop,
            left: _margin,
            right: _rightOfColumn,
            child: QuestFlag(
              quest: quest,
              open: questOpen,
              onToggle: onQuestToggle,
              onDetails: () => context.go('/quests'),
            ),
          ),
        if (DevConfig.isDevMode)
          Positioned(
            top: top + devTop,
            left: _margin,
            child: const DevFloatingButton(heroTag: 'map_dev_fab'),
          ),
      ],
    );
  }
}
