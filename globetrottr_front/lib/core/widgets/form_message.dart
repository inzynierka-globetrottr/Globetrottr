import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/unfold_in.dart';

/// A short message about a whole form, shown above its main button: an
/// error, or plain information. It unfolds when it appears.
class FormMessage extends StatelessWidget {
  const FormMessage.error(this.text, {super.key}) : _isError = true;

  const FormMessage.info(this.text, {super.key}) : _isError = false;

  final String text;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final style = context.typography.note;
    return UnfoldIn(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _isError ? style.copyWith(color: context.palette.danger) : style,
      ),
    );
  }
}
