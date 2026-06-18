import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_raised_container.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String _selectedTab = 'login';

  @override
  Widget build(BuildContext context) {
    const baseCanvasColor = AppColors.background;

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(
        baseColor: baseCanvasColor,
        shadowLightColor: AppColors.neuLight,
        shadowDarkColor: AppColors.neuShadow,
      ),
      child: Scaffold(
        backgroundColor: baseCanvasColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NeuFloatingContainer(child: Text('')),

                  const SizedBox(height: 32),

                  const NeuInsetContainer(child: Text('')),

                  const SizedBox(height: 32),

                  const NeuRaisedContainer(child: Text('')),

                  const SizedBox(height: 32),

                  const NeuTextField(
                    label: 'Email',
                    placeholder: 'example@domain.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 32),

                  const NeuTextField(
                    label: 'Password',
                    placeholder: '••••••••',
                    obscureText: true,
                  ),

                  const SizedBox(height: 32),

                  NeuPrimaryButton(label: 'Zaloguj się', onPressed: () {}),

                  const SizedBox(height: 32),

                  NeuSegmentedControl<String>(
                    selected: _selectedTab,
                    onChanged: (value) {
                      setState(() {
                        _selectedTab = value;
                      });
                    },
                    segments: const [
                      NeuSegment(label: 'Logowanie', value: 'login'),
                      NeuSegment(label: 'Rejestracja', value: 'register'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
