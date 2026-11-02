import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';
import 'package:globetrottr_front/core/localization/app_error_localizations.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/router/auth_routes.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/validators.dart';
import 'package:globetrottr_front/core/widgets/app_logo.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';
import 'package:globetrottr_front/core/widgets/neu_password_field.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/core/widgets/text_link.dart';
import 'package:globetrottr_front/debug/widgets/dev_floating_button.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/auth_footer_prompt.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/google_sign_in_button.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/or_divider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).clearError());
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .login(
          login: _loginController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      floatingActionButton: DevConfig.isDevMode
          ? const DevFloatingButton(heroTag: 'login_dev_fab')
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28, top + 45, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  const _LoginHeader(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: NeuTextField(
                      label: l10n.authLoginLabel,
                      placeholder: l10n.authNicknamePlaceholder,
                      leadingIcon: AppIcons.fieldUser,
                      controller: _loginController,
                      autofillHints: const [AutofillHints.username],
                      validator: (value) => validateUsername(value, l10n),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 8,
                    children: [
                      NeuPasswordField(
                        label: l10n.authPasswordLabel,
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        validator: (value) =>
                            validatePasswordPresent(value, l10n),
                      ),
                      TextLink(
                        text: l10n.authForgotPassword,
                        onTap: () => context.go(AuthRoutes.reset),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null)
                    FormMessage.error(
                      context.localizeErrorMessage(state.errorMessage),
                    ),
                  NeuPrimaryButton(
                    label: l10n.authSignIn,
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                  const OrDivider(),
                  GoogleSignInButton(
                    onPressed: state.isLoading
                        ? null
                        : notifier.signInWithGoogle,
                  ),
                  AuthFooterPrompt(
                    prompt: l10n.authNoAccount,
                    action: l10n.authCreateOne,
                    onAction: () => context.go(AuthRoutes.register),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 5,
            right: 20,
            child: NeuPillButton(
              label: l10n.authSkip,
              trailingIcon: AppIcons.chevronRight,
              onPressed: notifier.continueAsGuest,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) => Column(
    spacing: 22,
    children: [
      const AppLogo(),
      Text(
        context.l10n.appLogo,
        style: context.typography.display.copyWith(height: 1),
      ),
    ],
  );
}
