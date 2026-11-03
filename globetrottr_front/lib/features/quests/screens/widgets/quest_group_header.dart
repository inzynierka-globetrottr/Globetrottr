import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';

/// The icon and name of a group of quests, followed by a groove.
class QuestGroupHeader extends StatelessWidget {
  const QuestGroupHeader({super.key, required this.icon, required this.text});

  final AppIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      AppIcon(icon, size: 18, color: context.palette.accent),
      SectionHeader(text),
      const Expanded(child: NeuDivider()),
    ],
  );
}
