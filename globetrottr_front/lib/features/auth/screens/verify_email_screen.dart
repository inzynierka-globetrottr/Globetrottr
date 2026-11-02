import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/auth_config.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_code_field.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/auth_centered_layout.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/code_sent_header.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/resend_countdown.dart';

/// The code sent after a registration; a correct one signs the user in.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _incomplete = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final complete = _code.text.length == AuthConfig.codeLength;
    setState(() => _incomplete = !complete);
    if (complete) ref.read(authProvider.notifier).verifyEmail(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final stateError = state.errorFor(AuthForm.verify);
    final error = _incomplete
        ? l10n.validationCodeIncomplete
        : stateError == null
        ? null
        : context.localizeErrorMessage(stateError);

    return AuthCenteredLayout(
      children: [
        CodeSentHeader(
          title: l10n.authVerifyTitle,
          email: state.pendingVerificationEmail ?? '',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: NeuCodeField(
            controller: _code,
            semanticLabel: l10n.authCodeLabel,
          ),
        ),
        Text(
          l10n.authCodeValidity(AuthConfig.codeValidity.inMinutes),
          textAlign: TextAlign.center,
          style: context.typography.note,
        ),
        Column(
          spacing: 14,
          children: [
            if (error != null) FormMessage.error(error),
            NeuPrimaryButton(
              label: l10n.authVerify,
              isLoading: state.isLoading,
              onPressed: _submit,
            ),
            ResendCountdown(
              availableAt: state.resendAvailableAt,
              onResend: state.isLoading
                  ? null
                  : notifier.resendVerificationCode,
            ),
          ],
        ),
      ],
    );
  }
}
