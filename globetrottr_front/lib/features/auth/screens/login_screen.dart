import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';
import 'package:globetrottr_front/features/auth/provider/auth_mode.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/auth/provider/auth_state.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/form_divider.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/google_login_section.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/login_form.dart';

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

                  LoginForm(
                    state: state,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    onSubmit: () {
                      notifier.submit(
                        username: _usernameController.text,
                        password: _passwordController.text,
                        email: state.mode == AuthMode.register ? _emailController.text : null,
                      );
                    },
                  ),

                  FormDivider(),

                  GoogleLoginSection(
                    isLoading: state.isLoading,
                    onGooglePressed:() => notifier.signInWithGoogle(),
                  )
                ],
              ),
            ),
          )
        )
      ),
    );
  }
}