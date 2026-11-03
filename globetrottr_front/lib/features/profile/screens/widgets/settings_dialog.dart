import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_shadows.dart';
import 'package:globetrottr_front/core/theme/theme_context.dart';
import 'package:globetrottr_front/core/widgets/neu_surface.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final typography = context.typography;
    final currentLocale = ref.watch(localeProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.settingsTitle, style: typography.title),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.settingsLanguage, style: typography.note),
              const SizedBox(height: 12),
              _LocaleOption(
                label: l10n.settingsEnglish,
                isSelected: currentLocale?.languageCode == 'en',
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                },
              ),
              const SizedBox(height: 12),
              _LocaleOption(
                label: l10n.settingsPolish,
                isSelected: currentLocale?.languageCode == 'pl',
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('pl'));
                },
              ),
              const SizedBox(height: 12),
              _LocaleOption(
                label: l10n.settingsSystemDefault,
                isSelected: currentLocale == null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocaleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shadows = context.shadows;
    final color = isSelected ? palette.accent : palette.text;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: NeuSurface(
        shadows: isSelected
            ? shadows.inset(NeoDepth.sm)
            : shadows.raised(NeoDepth.sm),
        borderRadius: BorderRadius.circular(18),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.typography.itemTitle.copyWith(color: color),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? palette.accent : palette.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
