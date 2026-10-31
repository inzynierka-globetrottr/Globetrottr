import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AuthState state;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.state,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: formKey,
      child: Column(
        spacing: 18,
        children: [
          NeuTextField(
            controller: usernameController,
            placeholder: l10n.authUsernamePlaceholder,
            keyboardType: TextInputType.name,
            validator: (value) => validateUsername(value, l10n),
          ),

          if (state.mode == AuthMode.register)
            NeuTextField(
              controller: emailController,
              placeholder: l10n.authEmailPlaceholder,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => validateEmail(value, l10n),
            ),

          NeuTextField(
            controller: passwordController,
            placeholder: l10n.authPasswordPlaceholder,
            obscureText: true,
            validator: (value) => validatePassword(value, l10n),
          ),

          if (state.errorMessage != null)
            Text(
              context.localizeErrorMessage(state.errorMessage),
              style: AppTextStyles.descriptiveStatusAction.copyWith(
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),

          NeuPrimaryButton(
            label: state.isLoading
                ? l10n.authLoading
                : (state.mode == AuthMode.login
                      ? l10n.authSignIn
                      : l10n.authSignUp),
            onPressed: state.isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
