import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_code_field.dart';
import 'package:globetrottr_front/core/widgets/neu_password_field.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/auth_centered_layout.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/code_sent_header.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/resend_countdown.dart';

/// The reset code and the new password.
// TODO(data): nothing opens this screen until the backend can reset
// passwords; then wire the code check, the new password and resending.
class ResetPasswordCodeScreen extends ConsumerStatefulWidget {
  const ResetPasswordCodeScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordCodeScreen> createState() =>
      _ResetPasswordCodeScreenState();
}

class _ResetPasswordCodeScreenState
    extends ConsumerState<ResetPasswordCodeScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  late final DateTime _resendAvailableAt;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _resendAvailableAt = ref
        .read(clockProvider)()
        .add(AuthConfig.resendCooldown);
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showUnavailable() => setState(() => _unavailable = true);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthCenteredLayout(
      children: [
        CodeSentHeader(title: l10n.authNewPasswordTitle, email: widget.email),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: NeuCodeField(
            controller: _code,
            semanticLabel: l10n.authCodeLabel,
          ),
        ),
        NeuPasswordField(
          label: l10n.authNewPasswordLabel,
          controller: _password,
          autofillHints: const [AutofillHints.newPassword],
        ),
        Column(
          spacing: 14,
          children: [
            if (_unavailable) FormMessage.info(l10n.authResetUnavailable),
            NeuPrimaryButton(
              label: l10n.authChangePassword,
              onPressed: _showUnavailable,
            ),
            ResendCountdown(
              availableAt: _resendAvailableAt,
              onResend: _showUnavailable,
            ),
          ],
        ),
      ],
    );
  }
}
