import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/localization/locale_provider.dart';
import 'package:globetrottr_front/core/localization/localization_extensions.dart';
import 'package:globetrottr_front/core/theme/app_colors.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_container.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);

    return Dialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.neuLight, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settingsTitle,
                  style: AppTextStyles.screenHeaderLarge.copyWith(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textLight,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settingsLanguage,
              style: AppTextStyles.inputLabel.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _LocaleOption(
              label: l10n.settingsEnglish,
              isSelected: currentLocale?.languageCode == 'en',
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              },
            ),
            const SizedBox(height: 12),
            _LocaleOption(
              label: l10n.settingsPolish,
              isSelected: currentLocale?.languageCode == 'pl',
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('pl'));
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: NeuContainer(
        elevation: isSelected ? NeuElevation.inset : NeuElevation.floating,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        width: double.infinity,
        height: 52,
        color: isSelected ? AppColors.neuShadow : AppColors.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.actionButtonText.copyWith(
                  color: isSelected ? AppColors.accentBlue : AppColors.text,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.accentBlue : AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
