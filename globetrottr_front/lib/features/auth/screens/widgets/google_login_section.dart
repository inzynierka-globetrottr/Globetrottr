import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';

class GoogleLoginSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGooglePressed;

  const GoogleLoginSection({
    super.key,
    required this.isLoading,
    required this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return NeuButton(
      onPressed: isLoading ? null : onGooglePressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          const AppIcon(AppIcons.google),
          Text(context.l10n.authGoogleAccount),
        ],
      ),
    );
  }
}
