import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/widgets/neu_floating_container.dart';
import 'package:globetrottr_front/core/widgets/neu_inset_container.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_raised_container.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const baseCanvasColor = AppColors.background;

    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      darkTheme: const NeumorphicThemeData(
        baseColor: AppColors.background
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
                  NeuFloatingContainer(
                    child: Text("")
                  ),

                  const SizedBox(height: 32),

                  NeuInsetContainer(
                    child: Text("")
                  ),

                  const SizedBox(height: 32),

                  NeuRaisedContainer(
                    child: Text("")
                  ),

                  const SizedBox(height: 32),

                  NeuTextField(
                    label: 'Email',
                    placeholder: 'example@domain.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 32),

                  NeuTextField(
                    label: 'Password',
                    placeholder: '••••••••',
                    obscureText: true,
                  ),

                  const SizedBox(height: 32),

                  NeuPrimaryButton(
                    label: 'Zaloguj się',
                    onPressed: () {},
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