import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/map/provider/map_view_provider.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_view_option.dart';

Future<void> showLayersSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      // Over the navigation of the tabs rather than in the map tab under
      // it, so it hides the navigation and cannot be left open behind
      // another tab.
      useRootNavigator: true,
      // As tall as its content instead of the default part of the screen.
      isScrollControlled: true,
      builder: (_) => const LayersSheet(),
    );

/// Picks how the map shows what the user has discovered.
class LayersSheet extends ConsumerStatefulWidget {
  const LayersSheet({super.key});

  @override
  ConsumerState<LayersSheet> createState() => _LayersSheetState();
}

class _LayersSheetState extends ConsumerState<LayersSheet> {
  bool _unavailable = false;

  void _select(MapView view) {
    final selected = ref.read(mapViewProvider.notifier).select(view);
    setState(() => _unavailable = !selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = ref.watch(mapViewProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return NeuSurface(
      shadows: context.shadows.sheet,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Center(
            child: NeuSurface(
              shadows: context.shadows.inset(NeoDepth.xs),
              borderRadius: BorderRadius.circular(3),
              width: 48,
              height: 6,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mapLayers,
                  style: context.typography.titleLarge,
                ),
              ),
              NeuIconButton(
                size: 48,
                depth: NeoDepth.lg,
                semanticLabel: l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(),
                child: const AppIcon(AppIcons.close, size: 20),
              ),
            ],
          ),
          Semantics(
            container: true,
            child: Column(
              spacing: 12,
              children: [
                for (final view in MapView.values)
                  MapViewOption(
                    view: view,
                    selected: view == current,
                    onTap: () => _select(view),
                  ),
              ],
            ),
          ),
          if (_unavailable) FormMessage.info(l10n.mapViewUnavailable),
        ],
      ),
    );
  }
}
