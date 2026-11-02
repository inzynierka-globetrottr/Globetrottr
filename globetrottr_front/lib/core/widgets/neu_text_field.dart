import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A labelled input sunk into the page, with an optional icon in front and
/// a widget at the end (for example a button showing the password).
class NeuTextField extends StatefulWidget {
  const NeuTextField({
    super.key,
    this.label,
    this.placeholder,
    this.leadingIcon,
    this.trailing,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  static const _height = 58.0;

  final String? label;
  final String? placeholder;
  final AppIcons? leadingIcon;
  final Widget? trailing;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  String? _errorText;

  String? _validate(String? value) {
    final result = widget.validator?.call(value);
    if (result != _errorText) setState(() => _errorText = result);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(widget.label!, style: typography.label),
          ),
        NeuSurface(
          shadows: context.shadows.inset(NeoDepth.md),
          borderRadius: BorderRadius.circular(22),
          height: NeuTextField._height,
          padding: EdgeInsets.only(
            left: 18,
            right: widget.trailing == null ? 18 : 6,
          ),
          child: Row(
            spacing: 10,
            children: [
              if (widget.leadingIcon != null)
                AppIcon(
                  widget.leadingIcon!,
                  size: 20,
                  color: palette.textMuted,
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator == null ? null : _validate,
                  style: typography.input,
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.placeholder,
                    hintStyle: typography.input.copyWith(
                      color: palette.placeholder,
                    ),
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              _errorText!,
              style: typography.note.copyWith(color: palette.danger),
            ),
          ),
      ],
    );
  }
}
