import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class ProfileBio extends StatefulWidget {
  final String initialBio;
  final bool isUpdatingBio;
  final void Function(String) onSave;

  const ProfileBio({
    super.key,
    required this.initialBio,
    required this.isUpdatingBio,
    required this.onSave,
  });

  @override
  State<ProfileBio> createState() => _ProfileBioState();
}

class _ProfileBioState extends State<ProfileBio> {
  late TextEditingController _controller;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBio);
  }

  @override
  void didUpdateWidget(covariant ProfileBio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBio != widget.initialBio) {
      if (!_isModified) {
        _controller.text = widget.initialBio;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _isModified = value.trim() != widget.initialBio.trim();
    });
  }

  void _cancel() {
    _controller.text = widget.initialBio;
    FocusScope.of(context).unfocus();
    setState(() {
      _isModified = false;
    });
  }

  void _save() {
    widget.onSave(_controller.text.trim());
    FocusScope.of(context).unfocus();
    setState(() {
      _isModified = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeuSurface(
          shadows: context.shadows.inset(NeoDepth.md),
          borderRadius: BorderRadius.circular(22),
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 150,
            onChanged: _onChanged,
            style: typography.input,
            cursorColor: palette.accent,
            decoration: InputDecoration(
              hintText: l10n.profileBioPlaceholder,
              hintStyle: typography.input.copyWith(color: palette.placeholder),
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),
        if (_isModified) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textMuted,
                  textStyle: typography.action,
                ),
                child: Text(l10n.profileCancel),
              ),
              const SizedBox(width: 12),
              NeuButton(
                width: 90,
                height: 38,
                depth: NeoDepth.sm,
                onPressed: widget.isUpdatingBio ? null : _save,
                child: widget.isUpdatingBio
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.accent,
                        ),
                      )
                    : Text(
                        l10n.profileSave,
                        style: typography.action.copyWith(
                          color: palette.accent,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
