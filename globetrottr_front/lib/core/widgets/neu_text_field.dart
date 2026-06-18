import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';

class NeuTextField extends StatefulWidget {
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
  final String? Function(String?)? validator;

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
    this.validator,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  String? _localErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: widget.labelStyle ?? AppTextStyles.inputLabel,
          ),
          const SizedBox(height: 6),
        ],
        NeuInsetContainer(
          width: widget.width,
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: (value) {
                if (widget.validator != null) {
                  final result = widget.validator!(value);
                  setState(() {
                    _localErrorText = result;
                  });
                  return result;
                }
                return null;
              },
              style: widget.inputStyle ?? AppTextStyles.actionButtonText,
              decoration: InputDecoration(
                border: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: widget.placeholderStyle ?? AppTextStyles.inputLabel,
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
          ),
        ),

        if (_localErrorText != null) ...[
          const SizedBox(height: 6), // Gentle spacing below the container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _localErrorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
