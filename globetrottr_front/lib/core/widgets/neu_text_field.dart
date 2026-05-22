import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'neu_inset_container.dart';

class NeuTextField extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextStyle? labelStyle;
  final TextStyle? inputStyle;
  final TextStyle? placeholderStyle;
  final double width;
  final double height;

  const NeuTextField({
    super.key,
    this.label,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.labelStyle,
    this.inputStyle,
    this.placeholderStyle,
    this.width = double.infinity,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: labelStyle ?? AppTextStyles.inputLabel),
          const SizedBox(height: 6),
        ],
        NeuInsetContainer(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: inputStyle ?? AppTextStyles.actionButtonText,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: placeholderStyle ?? AppTextStyles.inputLabel,
              ),
            ),
          ),
        ),
      ],
    );
  }
}