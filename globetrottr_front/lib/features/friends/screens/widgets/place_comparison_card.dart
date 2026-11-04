import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/localization/measure_format.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/legend_dot.dart';
import 'package:globetrottr_front/core/widgets/neu_list_card.dart';
import 'package:globetrottr_front/features/friends/provider/friend_comparison.dart';

/// Places with the discovered part for the user and for the friend; the
/// larger part of each row is bold.
class PlaceComparisonCard extends StatelessWidget {
  const PlaceComparisonCard({super.key, required this.places});

  final List<PlaceComparison> places;

  @override
  Widget build(BuildContext context) => NeuListCard(
    rows: [for (final place in places) _PlaceRow(place: place)],
  );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place});

  final PlaceComparison place;

  static const _valueWidth = 62.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;
    final locale = Localizations.localeOf(context).toString();

    Widget share(double value, Color color, bool leads) => SizedBox(
      width: _valueWidth,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: LegendDot(
          color: color,
          size: 8,
          child: Text(
            context.l10n.mapPercent(
              formatKm2(value * 100, locale, decimals: 1),
            ),
            style: (leads ? typography.label : typography.note).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        spacing: 10,
        children: [
          Expanded(
            child: Text(
              place.name,
              style: typography.itemTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          share(
            place.myShare,
            palette.accent,
            place.myShare > place.friendShare,
          ),
          share(
            place.friendShare,
            palette.gold,
            place.friendShare > place.myShare,
          ),
        ],
      ),
    );
  }
}
