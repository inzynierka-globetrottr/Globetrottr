import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_pill_button.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';
import 'package:globetrottr_front/core/widgets/section_header.dart';

/// Gallery of the shared components, for checking them against the mock-up.
class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shadows = context.shadows;
    final typography = context.typography;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text('globetrottr', style: typography.display),
            Text('Headline', style: typography.headline),
            const SectionHeader('Section header'),
            const SizedBox(height: 24),
            for (final depthShadows in [shadows.raised, shadows.inset]) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final depth in NeoDepth.values)
                    NeuSurface(
                      shadows: depthShadows(depth),
                      borderRadius: BorderRadius.circular(18),
                      width: 44,
                      height: 44,
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const NeuTextField(
              label: 'Login lub nick',
              placeholder: 'np. odkrywca',
              leadingIcon: AppIcons.fieldUser,
            ),
            const SizedBox(height: 18),
            NeuPrimaryButton(label: 'Zaloguj się', onPressed: () {}),
            const SizedBox(height: 18),
            const NeuDivider(),
            const SizedBox(height: 18),
            NeuButton(
              onPressed: () {},
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [AppIcon(AppIcons.google), Text('Google')],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              spacing: 18,
              children: [
                for (final fill in NeuFill.values)
                  NeuIconButton(
                    fill: fill,
                    onPressed: () {},
                    child: const AppIcon(AppIcons.check, size: 18),
                  ),
                NeuPillButton(label: 'Pomiń', onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NeuBottomNavbar(activeItem: NavbarItem.map),
    );
  }
}
