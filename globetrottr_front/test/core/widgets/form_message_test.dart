import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/widgets/form_message.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    String text, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Center(child: FormMessage.error(text)),
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('a message fades in when it appears', (tester) async {
    await show(tester, 'Wrong password');

    expect(opacityOf(tester, 'Wrong password'), 0);

    await tester.pump(AppMotion.standard.medium ~/ 2);
    expect(opacityOf(tester, 'Wrong password'), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(opacityOf(tester, 'Wrong password'), 1);
  });

  testWidgets('a changed message replaces the old one', (tester) async {
    await show(tester, 'Wrong password');
    await tester.pumpAndSettle();
    await show(tester, 'No connection');
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Wrong password'), findsNothing);
  });

  testWidgets('without animations a message is shown at once', (
    tester,
  ) async {
    await show(tester, 'Wrong password', disableAnimations: true);
    await tester.pump();

    expect(opacityOf(tester, 'Wrong password'), 1);
  });
}
