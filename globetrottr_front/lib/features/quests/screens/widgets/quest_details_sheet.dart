import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_action.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_details_header.dart';

Future<void> showQuestDetailsSheet(
  BuildContext context, {
  required int questId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(baseColor: AppColors.background),
      child: QuestDetailsSheet(questId: questId),
    ),
  );
}

class QuestDetailsSheet extends ConsumerStatefulWidget {
  final int questId;

  const QuestDetailsSheet({super.key, required this.questId});

  @override
  ConsumerState<QuestDetailsSheet> createState() => _QuestDetailsSheetState();
}

class _QuestDetailsSheetState extends ConsumerState<QuestDetailsSheet> {
  bool _isStarting = false;
  String? _errorMessage;

  Future<void> _startQuest() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    String? error;
    try {
      await ref.read(questsProvider.notifier).startQuest(widget.questId);
    } on AppException catch (e) {
      error = e.message;
    }

    if (!mounted) return;
    setState(() {
      _isStarting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quest = ref
        .watch(questsProvider.select((state) => state.quests))
        .where((q) => q.id == widget.questId)
        .firstOrNull;

    if (quest == null) return const SizedBox.shrink();

    final description = quest.description;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QuestDetailsHeader(quest: quest),
            const SizedBox(height: 16),
            Text(
              description == null || description.isEmpty
                  ? 'No description yet.'
                  : description,
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 24),
            QuestDetailsAction(
              quest: quest,
              isStarting: _isStarting,
              onStart: _startQuest,
            ),
            if (_errorMessage case final String message) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.descriptiveStatusAction.copyWith(
                  color: AppColors.accentRed,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
