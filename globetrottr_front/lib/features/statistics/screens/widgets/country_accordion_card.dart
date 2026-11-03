import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/features/statistics/screens/widgets/country_flag_chip.dart';

class SubregionItem {
  const SubregionItem({
    required this.id,
    required this.name,
    this.onTap,
  });

  final int id;
  final String name;
  final VoidCallback? onTap;
}

class CountryAccordionCard extends StatefulWidget {
  const CountryAccordionCard({
    super.key,
    required this.countryCode,
    required this.countryName,
    required this.subtitle,
    required this.subregions,
    this.initiallyExpanded = false,
  });

  final String countryCode;
  final String countryName;
  final String subtitle;
  final List<SubregionItem> subregions;
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
          if (_expanded && widget.subregions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 16, 12),
              child: Column(
                children: [
                  for (final subregion in widget.subregions)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: subregion.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                subregion.name,
                                style: typography.action.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppIcon(
                              AppIcons.chevronRight,
                              size: 16,
                              color: palette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
