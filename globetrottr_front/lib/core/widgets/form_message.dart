import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A short message about a whole form, shown above its main button: an
/// error, or plain information.
class FormMessage extends StatelessWidget {
  const FormMessage.error(this.text, {super.key}) : _isError = true;

  const FormMessage.info(this.text, {super.key}) : _isError = false;

  final String text;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.note;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: _isError ? style.copyWith(color: context.palette.danger) : style,
    );
  }
}
