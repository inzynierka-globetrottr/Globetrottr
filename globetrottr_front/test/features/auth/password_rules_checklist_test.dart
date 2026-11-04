import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_icons.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/app_icon.dart';
import 'package:globetrottr_front/features/auth/screens/widgets/password_rules_checklist.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  Future<void> show(WidgetTester tester, String password) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PasswordRulesChecklist(password: password)),
    ),
  );

  int ticks(WidgetTester tester) => tester
      .widgetList<AppIcon>(find.byType(AppIcon))
      .where((icon) => icon.icon == AppIcons.check)
      .length;

  testWidgets('a rule that becomes met pops a tick in', (tester) async {
    await show(tester, '');
    expect(ticks(tester), 0);

    await show(tester, 'a');
    await tester.pump(AppMotion.standard.short ~/ 2);
    final popping = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (w) => w is AppIcon && w.icon == AppIcons.check,
            ),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    // It overshoots a little, which makes it pop.
    expect(popping.scale.value, allOf(greaterThan(0), isNot(1.0)));

    await tester.pumpAndSettle();
    expect(ticks(tester), 1);
  });
}
