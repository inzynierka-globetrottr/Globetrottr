import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/theme/app_theme.dart';
import 'package:globetrottr_front/core/widgets/neu_dialog.dart';

void main() {
  testWidgets('a dialog grows a little while it fades in', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );

    final result = showNeuDialog<bool>(
      context: context,
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('ok'),
      ),
    );
    await tester.pump();
    await tester.pump(AppMotion.standard.short ~/ 2);

    final scale = tester
        .widget<ScaleTransition>(
          find
              .ancestor(
                of: find.text('ok'),
                matching: find.byType(ScaleTransition),
              )
              .first,
        )
        .scale
        .value;
    expect(scale, inExclusiveRange(0.9, 1));

    await tester.pumpAndSettle();
    await tester.tap(find.text('ok'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}
