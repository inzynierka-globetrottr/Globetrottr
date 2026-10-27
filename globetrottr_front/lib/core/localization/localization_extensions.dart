import 'package:flutter/widgets.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

extension LocalizationContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
