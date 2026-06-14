import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/quests/providers/quest_provider.dart';
import 'package:globetrottr_front/features/quests/models/quest.dart';

enum QuestZone { unstarted, inProgress, completed }

class QuestDrawer extends ConsumerStatefulWidget {
  const QuestDrawer({super.key});

  @override
  ConsumerState<QuestDrawer> createState() => _QuestDrawerState();
}

class _QuestDrawerState extends ConsumerState<QuestDrawer> {
  QuestZone _expandedZone = QuestZone.unstarted;

  Future<void> _startQuest(int questId) async {
    try {
      final authService = ref.read(authServiceProvider);
      final questService = ref.read(questServiceProvider);

      final token = await authService.getToken();

      if (token == null) {
        throw Exception("Brak autoryzacji. Zaloguj się ponownie.");
      }

      await questService.startQuest(questId, token);
      
      ref.invalidate(userQuestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questsAsyncValue = ref.watch(userQuestsProvider);

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Tablica Questów',
                style: AppTextStyles.screenHeaderLarge,
              ),
            ),
            const Divider(color: AppColors.neuShadow, thickness: 2),

            Expanded(
              child: questsAsyncValue.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accentBlue),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Błąd: $error',
                      style: const TextStyle(color: AppColors.accentRed),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (quests) {
                  final unstarted = quests.where((q) => !q.isStarted).toList();
                  final inProgress = quests.where((q) => q.isStarted && !q.isCompleted).toList();
                  final completed = quests.where((q) => q.isCompleted).toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    children: [
                      _buildZoneSection(
                        title: 'Nowe wyzwania (${unstarted.length})',
                        zone: QuestZone.unstarted,
                        quests: unstarted,
                        icon: Icons.explore_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildZoneSection(
                        title: 'W trakcie (${inProgress.length})',
                        zone: QuestZone.inProgress,
                        quests: inProgress,
                        icon: Icons.run_circle_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildZoneSection(
                        title: 'Ukończone (${completed.length})',
                        zone: QuestZone.completed,
                        quests: completed,
                        icon: Icons.emoji_events_outlined,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSection({
    required String title,
    required QuestZone zone,
    required List<Quest> quests,
    required IconData icon,
  }) {
    final isExpanded = _expandedZone == zone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedZone = isExpanded ? _expandedZone : zone;
            });
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isExpanded ? AppColors.accentBlue : AppColors.textLight, 
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: isExpanded 
                      ? AppTextStyles.rulesetTitle.copyWith(color: AppColors.accentBlue) 
                      : AppTextStyles.rulesetTitle.copyWith(color: AppColors.textLight),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: isExpanded ? AppColors.accentBlue : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? (quests.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Brak questów w tej kategorii.', 
                        style: AppTextStyles.descriptiveStatusAction,
                      ),
                    )
                  : Column(
                      children: quests.map((q) => _buildQuestCard(q, zone)).toList(),
                    ))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildQuestCard(Quest quest, QuestZone zone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeuFloatingContainer(
        width: double.infinity,
        height: zone == QuestZone.unstarted ? 140 : 90,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title, 
                          style: AppTextStyles.actionButtonText, 
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (zone == QuestZone.inProgress)
                          Text(
                            '${(quest.progress * 100).toInt()}% postępu', 
                            style: AppTextStyles.descriptiveStatusAction.copyWith(color: AppColors.accentBlue),
                          ),
                        if (zone == QuestZone.completed)
                          Text(
                            'Ukończono', 
                            style: AppTextStyles.descriptiveStatusAction.copyWith(color: AppColors.accentGreen),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.star_rounded, 
                        color: AppColors.accentGold, 
                        size: 24,
                      ),
                      Text(
                        '${quest.rewardPoints} XP', 
                        style: AppTextStyles.inputLabel.copyWith(color: AppColors.accentGold),
                      ),
                    ],
                  ),
                ],
              ),

              if (zone == QuestZone.unstarted) ...[
                const Spacer(),
                NeuPrimaryButton(
                  height: 36,
                  label: "Zacznij Quest",
                  labelStyle: AppTextStyles.tabButtonText.copyWith(color: AppColors.accentBlue),
                  onPressed: () => _startQuest(quest.id),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}