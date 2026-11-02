import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_state.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_accordion_section.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_card.dart';

// TODO(neo): temporary list until the Quests tab of the mock-up is approved.
class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  QuestZone _expandedZone = QuestZone.unstarted;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(questsProvider.notifier).loadQuests());
  }

  Future<void> _startQuest(int questId) async {
    try {
      await ref.read(questsProvider.notifier).startQuest(questId);
    } on AppException catch (e) {
      if (mounted) _showError(context.localizeErrorMessage(e.message));
    } catch (e) {
      debugPrint('Unexpected error starting quest: $e');
      if (mounted) _showError(context.l10n.errorSomethingWentWrongTryAgain);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.palette.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                context.l10n.questsBoardTitle,
                style: context.typography.headline,
              ),
            ),
            const NeuDivider(),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
      bottomNavigationBar: const NeuBottomNavbar(
        activeItem: NavbarItem.quests,
      ),
    );
  }

  Widget _buildBody(QuestsState state) {
    final l10n = context.l10n;
    final palette = context.palette;

    if (state.isLoading) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.localizeErrorMessage(state.errorMessage),
            style: context.typography.body.copyWith(color: palette.danger),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final unstarted = state.quests.where((q) => !q.isStarted).toList();
    final inProgress = state.quests
        .where((q) => q.isStarted && !q.isCompleted)
        .toList();
    final completed = state.quests.where((q) => q.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      children: [
        QuestAccordionSection(
          title: l10n.questsAvailableSection(unstarted.length),
          zone: QuestZone.unstarted,
          quests: unstarted,
          icon: Icons.explore_outlined,
          isExpanded: _expandedZone == QuestZone.unstarted,
          onToggle: () => setState(() => _expandedZone = QuestZone.unstarted),
          onStartQuest: _startQuest,
        ),
        const SizedBox(height: 16),
        QuestAccordionSection(
          title: l10n.questsInProgressSection(inProgress.length),
          zone: QuestZone.inProgress,
          quests: inProgress,
          icon: Icons.run_circle_outlined,
          isExpanded: _expandedZone == QuestZone.inProgress,
          onToggle: () => setState(() => _expandedZone = QuestZone.inProgress),
          onStartQuest: _startQuest,
        ),
        const SizedBox(height: 16),
        QuestAccordionSection(
          title: l10n.questsCompletedSection(completed.length),
          zone: QuestZone.completed,
          quests: completed,
          icon: Icons.emoji_events_outlined,
          isExpanded: _expandedZone == QuestZone.completed,
          onToggle: () => setState(() => _expandedZone = QuestZone.completed),
          onStartQuest: _startQuest,
        ),
      ],
    );
  }
}
