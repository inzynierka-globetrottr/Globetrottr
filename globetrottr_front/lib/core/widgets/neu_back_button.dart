import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:go_router/go_router.dart';

/// Goes back to the previous screen.
class NeuBackButton extends StatelessWidget {
  const NeuBackButton({super.key, this.onPressed});

  /// Pops the current route when null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => NeuIconButton(
    size: 50,
    depth: NeoDepth.lg,
    semanticLabel: context.l10n.commonBack,
    onPressed: onPressed ?? () => context.pop(),
    child: const AppIcon(AppIcons.chevronLeft),
  );
}
