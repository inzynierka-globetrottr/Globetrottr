import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';
import 'package:globetrottr_front/features/quests/data/quest.dart';
import 'package:globetrottr_front/features/quests/provider/quest_board_provider.dart';
import 'package:globetrottr_front/features/quests/provider/quests_provider.dart';
import 'package:globetrottr_front/features/quests/screens/widgets/quest_list_item.dart';

/// The completed quests, newest first, grouped by the month they were
/// completed in.
class QuestHistoryScreen extends ConsumerStatefulWidget {
  const QuestHistoryScreen({super.key});

  @override
  ConsumerState<QuestHistoryScreen> createState() => _QuestHistoryScreenState();
}

class _QuestHistoryScreenState extends ConsumerState<QuestHistoryScreen> {
  static const _side = 20.0;

  int? _openQuestId;

  // Opened over the Quests tab, which has its quests already; only a
  // screen opened on its own has to load them.
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(questsProvider.notifier).loadQuestsOnce(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.typography;
    final completed = ref.watch(questBoardProvider).completed;
    final locale = Localizations.localeOf(context).toString();
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          _side,
          padding.top + 24,
          _side,
          padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Row(
              spacing: 12,
              children: [
                const NeuBackButton(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.questsHistoryTitle, style: typography.title),
                      Text(
                        l10n.questsCompletedCount(completed.length),
                        style: typography.note,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final month in _byMonth(completed, locale)) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: SectionHeader(month.name),
              ),
              NeuListCard(
                rows: [
                  for (final quest in month.quests)
                    QuestListItem(
                      key: ValueKey(quest.id),
                      quest: quest,
                      expanded: _openQuestId == quest.id,
                      onToggle: () => setState(
                        () => _openQuestId = _openQuestId == quest.id
                            ? null
                            : quest.id,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef _Month = ({String name, List<Quest> quests});

/// [quests] are newest first; one without a date falls into the month of
/// the one before it, or into the first month.
List<_Month> _byMonth(List<Quest> quests, String locale) {
  final months = <_Month>[];
  String? current;
  for (final quest in quests) {
    final date = quest.completedAt;
    final name = date == null ? current : formatMonth(date, locale);
    if (months.isEmpty || (name != null && name != current)) {
      months.add((name: name ?? '', quests: []));
      current = name;
    }
    months.last.quests.add(quest);
  }
  return months;
}
