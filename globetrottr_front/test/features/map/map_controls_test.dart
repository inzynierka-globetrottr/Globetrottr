import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/features/map/screens/widgets/map_controls.dart';
import 'package:globetrottr_front/l10n/app_localizations.dart';

void main() {
  var recentred = 0;

  Future<void> pump(WidgetTester tester) async {
    recentred = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: MapControls(onLayers: () {}, onRecenter: () => recentred++),
        ),
      ),
    );
  }

  testWidgets('a tap anywhere on the control counts', (tester) async {
    await pump(tester);
    final control = find.bySemanticsLabel('Center on my position');
    final box = tester.getRect(control);

    await tester.tapAt(box.topLeft + const Offset(4, 4));

    expect(recentred, 1);
  });
}
