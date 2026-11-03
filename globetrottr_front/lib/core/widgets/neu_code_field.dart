import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

/// A numeric code typed into a row of sunken cells, one digit each. An
/// invisible text field on top takes the taps and the keyboard input.
class NeuCodeField extends StatefulWidget {
  const NeuCodeField({
    super.key,
    required this.controller,
    required this.semanticLabel,
    this.length = AuthConfig.codeLength,
  });

  final TextEditingController controller;
  final String semanticLabel;
  final int length;

  @override
  State<NeuCodeField> createState() => _NeuCodeFieldState();
}

class _NeuCodeFieldState extends State<NeuCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Stack(
      children: [
        Row(
          spacing: 8,
          children: [
            for (var i = 0; i < widget.length; i++)
              Expanded(
                child: _CodeCell(
                  digit: i < text.length ? text[i] : null,
                  cursorKey: ValueKey('code-cursor-$i'),
                  isNext: _focus.hasFocus && i == text.length,
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                semanticCounterText: '',
                labelText: widget.semanticLabel,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeCell extends StatelessWidget {
  const _CodeCell({
    required this.digit,
    required this.cursorKey,
    required this.isNext,
  });

  static const _height = 62.0;
  static const _radius = 18.0;

  /// Space between the cell and the focus outline.
  static const _outlineGap = 3.0;
  static const _outlineWidth = 2.0;

  final String? digit;
  final Key cursorKey;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    final cell = NeuSurface(
      shadows: context.shadows.inset(NeoDepth.md),
      borderRadius: BorderRadius.circular(_radius),
      height: _height,
      child: Center(
        child: digit != null
            ? Text(
                digit!,
                style: context.typography.digit.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            : isNext
            ? SizedBox(
                key: cursorKey,
                width: 2,
                height: 28,
                child: ColoredBox(color: accent),
              )
            : null,
      ),
    );
    if (!isNext) return cell;

    const inset = -(_outlineGap + _outlineWidth);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cell,
        Positioned.fill(
          left: inset,
          top: inset,
          right: inset,
          bottom: inset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: accent, width: _outlineWidth),
                borderRadius: BorderRadius.circular(
                  _radius + _outlineGap + _outlineWidth,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
