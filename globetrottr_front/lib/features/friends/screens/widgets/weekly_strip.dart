import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/features/friends/provider/friend_activity_provider.dart';
import 'package:globetrottr_front/features/friends/screens/widgets/weekly_person.dart';

/// "This week": the user and the friends who discovered something, largest
/// area first. Four fill the width; with more the row scrolls and the next
/// person peeks in at the edge, so it is clear there is more.
class WeeklyStrip extends ConsumerWidget {
  const WeeklyStrip({super.key, required this.sidePadding});

  /// The screen margin the row lines up with.
  final double sidePadding;

  static const _fitting = 4;

  /// How much of the next person shows at the edge.
  static const _peek = 26.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(weeklyRankingProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scrolls = entries.length > _fitting;
        final gap = scrolls
            ? (width - sidePadding - _fitting * WeeklyPerson.width - _peek) /
                  _fitting
            : (width - 2 * sidePadding - _fitting * WeeklyPerson.width) /
                  (_fitting - 1);
        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: gap,
          children: [for (final e in entries) WeeklyPerson(entry: e)],
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: scrolls ? null : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          clipBehavior: Clip.none,
          child: row,
        );
      },
    );
  }
}
