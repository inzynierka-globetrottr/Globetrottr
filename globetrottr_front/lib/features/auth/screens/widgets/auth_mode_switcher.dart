import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';

class AuthModeSwitcher extends StatelessWidget {
  final AuthMode currentMode;
  final ValueChanged<AuthMode> onModeChanged;

  const AuthModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSegmentedControl<AuthMode>(
      selected: currentMode,
      onChanged: onModeChanged,
      segments: const [
        NeuSegment(label: 'Sign in', value: AuthMode.login),
        NeuSegment(label: 'Sign up', value: AuthMode.register),
      ],
    );
  }
}