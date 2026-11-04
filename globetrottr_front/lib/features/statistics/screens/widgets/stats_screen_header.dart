import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';

/// Back button, title and an optional subtitle at the top of a statistics
/// screen.
class StatsScreenHeader extends StatelessWidget {
  const StatsScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Row(
      children: [
        const NeuBackButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: typography.title),
              if (subtitle != null) Text(subtitle!, style: typography.note),
            ],
          ),
        ),
      ],
    );
  }
}
