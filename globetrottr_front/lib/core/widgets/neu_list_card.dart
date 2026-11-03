import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A raised card holding rows separated by grooves.
class NeuListCard extends StatelessWidget {
  const NeuListCard({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => NeuSurface(
    shadows: context.shadows.raised(NeoDepth.xl),
    borderRadius: BorderRadius.circular(24),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const NeuDivider(),
          rows[i],
        ],
      ],
    ),
  );
}
