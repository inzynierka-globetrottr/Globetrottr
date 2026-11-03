import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';

/// A password input with dots as its hint and a button that shows or hides
/// the password.
class NeuPasswordField extends StatefulWidget {
  const NeuPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  State<NeuPasswordField> createState() => _NeuPasswordFieldState();
}

class _NeuPasswordFieldState extends State<NeuPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NeuTextField(
      label: widget.label,
      placeholder: l10n.authPasswordPlaceholder,
      leadingIcon: AppIcons.fieldLock,
      obscureText: _obscured,
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      trailing: NeuIconButton(
        semanticLabel: _obscured
            ? l10n.authShowPassword
            : l10n.authHidePassword,
        onPressed: () => setState(() => _obscured = !_obscured),
        child: AppIcon(_obscured ? AppIcons.eye : AppIcons.eyeOff, size: 18),
      ),
    );
  }
}
