import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';

/// A short message about a whole form, shown above its main button: an
/// error, or plain information. It unfolds and fades in when it appears.
class FormMessage extends StatefulWidget {
  const FormMessage.error(this.text, {super.key}) : _isError = true;

  const FormMessage.info(this.text, {super.key}) : _isError = false;

  final String text;
  final bool _isError;

  @override
  State<FormMessage> createState() => _FormMessageState();
}

class _FormMessageState extends State<FormMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(vsync: this);
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: _appear,
    curve: Curves.linear,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _appear.duration = motion.medium;
    _curved.curve = motion.curve;
    if (_appear.isDismissed) _appear.forward();
  }

  @override
  void dispose() {
    _curved.dispose();
    _appear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.typography.note;
    return SizeTransition(
      sizeFactor: _curved,
      alignment: Alignment.topCenter,
      fixedCrossAxisSizeFactor: 1,
      child: FadeTransition(
        opacity: _curved,
        child: Text(
          widget.text,
          textAlign: TextAlign.center,
          style: widget._isError
              ? style.copyWith(color: context.palette.danger)
              : style,
        ),
      ),
    );
  }
}
