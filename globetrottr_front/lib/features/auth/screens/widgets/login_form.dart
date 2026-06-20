import 'package:flutter/material.dart';
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
    return Form(
      key: formKey,
      child: Column(
        spacing: 18,
        children: [
          NeuTextField(
            controller: usernameController,
            placeholder: 'Username',
            keyboardType: TextInputType.name,
            validator: validateUsername,
          ),

          if (state.mode == AuthMode.register)
            NeuTextField(
              controller: emailController,
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail
            ),

          NeuTextField(
            controller: passwordController,
            placeholder: 'Password',
            obscureText: true,
            validator: validatePassword
          ),

          if (state.errorMessage != null)
            Text(
              state.errorMessage!,
              style: AppTextStyles.descriptiveStatusAction.copyWith(
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),

          NeuPrimaryButton(
            label: state.isLoading
                ? 'Loading...'
                : (state.mode == AuthMode.login ? 'Sign in' : 'Sign up'),
            onPressed: state.isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
