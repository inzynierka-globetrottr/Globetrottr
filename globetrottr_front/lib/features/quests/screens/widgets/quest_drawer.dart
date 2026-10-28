import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_state.dart';
import 'package:globetrottr_front/features/quests/data/quest_zone.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_accordion_section.dart';

class QuestDrawer extends ConsumerStatefulWidget {
  const QuestDrawer({super.key});

  @override
  ConsumerState<QuestDrawer> createState() => _QuestDrawerState();
}

class _QuestDrawerState extends ConsumerState<QuestDrawer> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.localizeErrorMessage(e.message)),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Unexpected error starting quest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorSomethingWentWrongTryAgain),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(questsProvider);

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                l10n.questsBoardTitle,
                style: AppTextStyles.screenHeaderLarge,
              ),
            ),
            const Divider(color: AppColors.neuShadow, thickness: 2),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(QuestsState state) {
    final l10n = context.l10n;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.localizeErrorMessage(state.errorMessage),
            style: const TextStyle(color: AppColors.accentRed),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
