import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/features/profile/provider/profile_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/active_quest.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quest_level_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quest_map_focus.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/active_quest_card.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/empty_active_quest_card.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_group_header.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_level_row.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_list_item.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_swap_dialog.dart';
import 'package:go_router/go_router.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  static const _side = 20.0;

  int? _openQuestId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(questsProvider.notifier).loadQuests();
      if (ref.read(profileProvider).profile == null) {
        ref.read(profileProvider.notifier).loadProfile();
      }
    });
  }

  void _toggle(Quest quest) => setState(
    () => _openQuestId = _openQuestId == quest.id ? null : quest.id,
  );

  Future<void> _start(Quest quest) async {
    final active = ref.read(activeQuestProvider);
    if (active != null &&
        !await confirmQuestSwap(context, active: active, next: quest)) {
      return;
    }
    try {
      await ref.read(questsProvider.notifier).startQuest(quest.id);
      if (mounted) setState(() => _openQuestId = null);
    } on AppException catch (e) {
      if (mounted) _showError(context.localizeErrorMessage(e.message));
    }
  }

  void _showOnMap() {
    ref.read(questMapFocusProvider.notifier).request();
    context.go('/map');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(questsProvider);
    final active = ref.watch(activeQuestProvider);
    final board = ref.watch(questBoardProvider);

    Widget group(AppIcons icon, String title, List<Quest> quests) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        QuestGroupHeader(icon: icon, text: title),
        NeuListCard(
          rows: [
            for (final quest in quests)
              QuestListItem(
                key: ValueKey(quest.id),
                quest: quest,
                expanded: _openQuestId == quest.id,
                onToggle: () => _toggle(quest),
                onStart: () => _start(quest),
                swaps: active != null,
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      // The list scrolls on under the floating navigation.
      extendBody: true,
      bottomNavigationBar: const NeuBottomNavbar(
        activeItem: NavbarItem.quests,
      ),
      // Read inside the scaffold, whose padding includes the navigation.
      body: Builder(
        builder: (context) => SingleChildScrollView(
          padding: _scrollPadding(MediaQuery.paddingOf(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Text(l10n.questsTitle, style: context.typography.headline),
              QuestLevelRow(
                level: ref.watch(questLevelProvider),
                onTap: () => context.go('/quests/history'),
              ),
              if (state.errorMessage != null)
                FormMessage.error(
                  context.localizeErrorMessage(state.errorMessage),
                ),
              if (active != null)
                ActiveQuestCard(quest: active, onShow: _showOnMap)
              else
                const EmptyActiveQuestCard(),
              if (board.places.isNotEmpty)
                group(AppIcons.pin, l10n.questsPlaces, board.places),
              if (board.routes.isNotEmpty)
                group(AppIcons.route, l10n.questsRoutes, board.routes),
            ],
          ),
        ),
      ),
    );
  }

  static EdgeInsets _scrollPadding(EdgeInsets safe) =>
      EdgeInsets.fromLTRB(_side, safe.top + 24, _side, safe.bottom + 20);
}
