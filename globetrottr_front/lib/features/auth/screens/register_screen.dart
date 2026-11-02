import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_password_field.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/auth_footer_prompt.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/google_sign_in_button.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/or_divider.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/password_strength_meter.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nickController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).clearError());
  }

  @override
  void dispose() {
    _nickController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .register(
          username: _nickController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authProvider);
    final top = MediaQuery.paddingOf(context).top;

    ref.listen<AuthState>(authProvider, (previous, next) {
      final email = next.pendingVerificationEmail;
      if (email != null && email != previous?.pendingVerificationEmail) {
        context.go(AuthRoutes.verify);
      }
    });

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, top + 77, 28, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.authRegisterTitle,
                  style: context.typography.display.copyWith(height: 1.05),
                ),
              ),
              NeuTextField(
                label: l10n.authNicknameLabel,
                placeholder: l10n.authNicknamePlaceholder,
                leadingIcon: AppIcons.fieldUser,
                controller: _nickController,
                autofillHints: const [AutofillHints.newUsername],
                validator: (value) => validateUsername(value, l10n),
              ),
              NeuTextField(
                label: l10n.authEmailLabel,
                placeholder: l10n.authEmailPlaceholder,
                leadingIcon: AppIcons.fieldMail,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) => validateEmail(value, l10n),
              ),
              NeuPasswordField(
                label: l10n.authPasswordLabel,
                controller: _passwordController,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => validatePassword(value, l10n),
              ),
              ValueListenableBuilder(
                valueListenable: _passwordController,
                builder: (context, value, _) => PasswordStrengthMeter(
                  strength: passwordStrength(value.text),
                ),
              ),
              if (state.errorMessage != null)
                FormMessage.error(
                  context.localizeErrorMessage(state.errorMessage),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: NeuPrimaryButton(
                  label: l10n.authCreateAccount,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
              ),
              const OrDivider(),
              GoogleSignInButton(
                onPressed: state.isLoading
                    ? null
                    : ref.read(authProvider.notifier).signInWithGoogle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AuthFooterPrompt(
                  prompt: l10n.authHaveAccount,
                  action: l10n.authSignIn,
                  onAction: () => context.go(AuthRoutes.login),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
