import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/exceptions/app_exception.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/features/friends/provider/friends_provider.dart';

class SearchSendRow extends ConsumerStatefulWidget {
  const SearchSendRow({super.key});

  @override
  ConsumerState<SearchSendRow> createState() => _SearchSendRowState();
}

class _SearchSendRowState extends ConsumerState<SearchSendRow> {
  final TextEditingController _controller = TextEditingController();
  String? _feedbackMessage;
  bool _isSuccess = false;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFeedback(String message, bool success) {
    setState(() {
      _feedbackMessage = message;
      _isSuccess = success;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _onSend() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    final l10n = context.l10n;
    setState(() => _isSending = true);

    try {
      await ref.read(friendsProvider.notifier).sendInvite(username);
      _controller.clear();
      _showFeedback(l10n.friendsInviteSent(username), true);
    } on AppException catch (e) {
      if (mounted) {
        _showFeedback(context.localizeErrorMessage(e.message), false);
      }
    } catch (_) {
      if (mounted) {
        _showFeedback(l10n.errorNetworkShort, false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: NeuTextField(
                controller: _controller,
                placeholder: l10n.friendsSearchPlaceholder,
              ),
            ),
            const SizedBox(width: 12),
            NeuIconButton(
              onPressed: _isSending ? null : _onSend,
              child: Icon(Icons.send, color: palette.accent),
            ),
          ],
        ),
        if (_feedbackMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _feedbackMessage!,
              style: context.typography.caption.copyWith(
                color: _isSuccess ? palette.accent : palette.danger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
