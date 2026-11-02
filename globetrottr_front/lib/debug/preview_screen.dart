import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/core/widgets/neu_bottom_navbar.dart';
import 'package:globetrottr_front/core/widgets/neu_button.dart';
import 'package:globetrottr_front/core/widgets/neu_divider.dart';
import 'package:globetrottr_front/core/widgets/neu_icon_button.dart';
import 'package:globetrottr_front/core/widgets/neu_primary_button.dart';
import 'package:globetrottr_front/core/widgets/neu_segmented_control.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';

/// Gallery of the shared components, for checking them against the mock-up.
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String _selectedTab = 'login';

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
            Text('SECTION LABEL', style: typography.sectionLabel),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final depth in NeoDepth.values)
                  NeuSurface(
                    shadows: shadows.raised(depth),
                    borderRadius: BorderRadius.circular(18),
                    width: 44,
                    height: 44,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final depth in NeoDepth.values)
                  NeuSurface(
                    shadows: shadows.inset(depth),
                    borderRadius: BorderRadius.circular(18),
                    width: 44,
                    height: 44,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const NeuTextField(
              label: 'Login lub nick',
              placeholder: 'np. odkrywca',
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
              children: [
                NeuIconButton(
                  onPressed: () {},
                  child: const AppIcon(AppIcons.navProfile, size: 18),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: NeuSegmentedControl<String>(
                    selected: _selectedTab,
                    onChanged: (value) => setState(() => _selectedTab = value),
                    segments: const [
                      NeuSegment(label: 'Logowanie', value: 'login'),
                      NeuSegment(label: 'Rejestracja', value: 'register'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const NeuBottomNavbar(activeItem: NavbarItem.map),
    );
  }
}
