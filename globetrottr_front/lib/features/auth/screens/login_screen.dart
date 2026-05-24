import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenWidget();
}

class _LoginScreenWidget extends ConsumerState<LoginScreen> {

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseCanvasColor = AppColors.background;

    final state = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        // TODO: route to map screen
      }
    });

    // TODO: refactor, this file is too big
    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(
        baseColor: baseCanvasColor
      ),
      child: Scaffold(
        backgroundColor: baseCanvasColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 18,
                children: [

                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      "globetrottr",
                      style: AppTextStyles.appLogo,
                    )
                  ),

                  NeuSegmentedControl<AuthMode>(
                    selected: state.mode,
                    onChanged: (value) {notifier.setMode(value);},
                    segments: const [
                      NeuSegment(label: 'Sign in', value: AuthMode.login),
                      NeuSegment(label: 'Sign up', value: AuthMode.register),
                    ],
                  ),

                  NeuTextField(
                    controller: _usernameController,
                    placeholder: 'Username',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  if (state.mode == AuthMode.register)
                    NeuTextField(
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),

                  NeuTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    obscureText: true,
                  ),

                  if (state.errorMessage != null)
                    Text(
                      state.errorMessage!,
                      style: AppTextStyles.descriptiveStatusAction.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),

                  NeuPrimaryButton(
                    label: state.isLoading
                        ? 'Loading...'
                        : (state.mode == AuthMode.login ? 'Sign in' : 'Sign up'),
                    onPressed: state.isLoading ? null : () {
                      if (state.isLoading) return;

                      notifier.submit(
                        username: _usernameController.text,
                        password: _passwordController.text,
                        email: _emailController.text,
                      );
                    },
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  NeuPrimaryButton(
                    onPressed: () {
                      if (state.isLoading) return;

                      notifier.signInWithGoogle();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'G',
                            style: AppTextStyles.rulesetTitle
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Google Account',
                          style: AppTextStyles.actionButtonText
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        )
      ),
    );
  }
}