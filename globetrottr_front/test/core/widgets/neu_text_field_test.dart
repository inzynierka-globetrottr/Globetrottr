import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_text_field.dart';

void main() {
  final formKey = GlobalKey<FormState>();

  Future<void> showInvalid(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: NeuTextField(
              label: 'Login',
              validator: (value) => 'Enter your login',
            ),
          ),
        ),
      ),
    );
    formKey.currentState!.validate();
    await tester.pump();
  }

  double errorOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('Enter your login'),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('a field error unfolds under the field', (tester) async {
    await showInvalid(tester);

    expect(errorOpacity(tester), 0);

    await tester.pump(AppMotion.standard.medium ~/ 2);
    expect(errorOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(errorOpacity(tester), 1);
  });
}
