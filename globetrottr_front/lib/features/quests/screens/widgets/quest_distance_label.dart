import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';

class QuestDistanceLabel extends StatelessWidget {
  final String label;

  const QuestDistanceLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    const style = AppTextStyles.descriptiveStatusAction;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.near_me_outlined,
          color: style.color,
          size: style.fontSize! + 2,
        ),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}
