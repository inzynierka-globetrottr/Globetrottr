import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_flag_chip.dart';

class SubregionItem {
  const SubregionItem({required this.id, required this.name, this.onTap});

  final int id;
  final String name;
  final VoidCallback? onTap;
}

/// A state of a country with the cities discovered in it.
class SubregionGroup {
  const SubregionGroup({required this.header, required this.items});

  final SubregionItem header;
  final List<SubregionItem> items;
}

class CountryAccordionCard extends StatefulWidget {
  const CountryAccordionCard({
    super.key,
    required this.countryCode,
    required this.countryName,
    required this.subtitle,
    required this.groups,
    this.initiallyExpanded = false,
  });

  final String? countryCode;
  final String countryName;
  final String subtitle;
  final List<SubregionGroup> groups;
  final bool initiallyExpanded;

  @override
  State<CountryAccordionCard> createState() => _CountryAccordionCardState();
}

class _CountryAccordionCardState extends State<CountryAccordionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;

    return NeuSurface(
      shadows: context.shadows.raised(NeoDepth.xl),
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CountryFlagChip(
                    countryCode: widget.countryCode,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.countryName,
                          style: typography.itemTitle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: typography.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: AppIcon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.groups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in widget.groups) ...[
                    _row(context, group.header, isHeader: true),
                    for (final item in group.items)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _row(context, item, isHeader: false),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    SubregionItem item, {
    required bool isHeader,
  }) {
    final palette = context.palette;
    final typography = context.typography;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: isHeader
                    ? typography.action.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      )
                    : typography.body.copyWith(color: palette.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.onTap != null) ...[
              const SizedBox(width: 8),
              AppIcon(
                AppIcons.chevronRight,
                size: 16,
                color: palette.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
