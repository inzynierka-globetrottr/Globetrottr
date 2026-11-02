import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A row of a list: an avatar or icon, a title with an optional line under
/// it, and actions at the end.
class NeuListRow extends StatelessWidget {
  const NeuListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing = const [],
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: 12,
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: typography.itemTitle,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: typography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}
