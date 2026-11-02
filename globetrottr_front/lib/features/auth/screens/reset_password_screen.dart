import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/auth_centered_layout.dart';

/// Asks for the address a reset code is sent to.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _unavailable = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(data): send the code once the backend can reset passwords, then
    // open AuthRoutes.resetCode with the address.
    setState(() => _unavailable = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthCenteredLayout(
      children: [
        Text(
          l10n.authForgotPassword,
          textAlign: TextAlign.center,
          style: context.typography.headline.copyWith(height: 1.1),
        ),
        Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: NeuTextField(
              label: l10n.authEmailLabel,
              placeholder: l10n.authEmailPlaceholder,
              leadingIcon: AppIcons.fieldMail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) => validateEmail(value, l10n),
            ),
          ),
        ),
        if (_unavailable) FormMessage.info(l10n.authResetUnavailable),
        NeuPrimaryButton(label: l10n.authSendCode, onPressed: _submit),
      ],
    );
  }
}
