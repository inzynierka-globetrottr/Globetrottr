import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';

class ProfileBio extends StatefulWidget {
  final String initialBio;
  final Function(String) onSave;

  const ProfileBio({
    super.key,
    required this.initialBio,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeuInsetContainer(
          width: double.infinity,
          height: 110,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 150,
              onChanged: _onChanged,
              style: AppTextStyles.actionButtonText,
              decoration: InputDecoration(
                hintText: 'Tell others about your journeys...',
                hintStyle: AppTextStyles.inputLabel.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.6),
                ),
                counterText: '',
                border: InputBorder.none,
              ),
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
                  foregroundColor: AppColors.textLight,
                  textStyle: AppTextStyles.inputLabel.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              NeuPrimaryButton(
                label: 'Save',
                width: 90,
                height: 38,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ],
    );
  }
}