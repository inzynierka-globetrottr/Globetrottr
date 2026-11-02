import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/widgets/neu_code_field.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NeuCodeField(controller: controller, semanticLabel: 'Code'),
      ),
    ),
  );

  testWidgets('shows each typed digit in its own cell', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '4821');
    await tester.pump();

    for (final digit in ['4', '8', '2', '1']) {
      expect(find.text(digit), findsOneWidget);
    }
    expect(controller.text, '4821');
  });

  testWidgets('accepts only digits, up to the code length', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();

    expect(controller.text, '123456');
  });

  testWidgets('marks the cell of the next digit while focused', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(NeuCodeField));
    await tester.enterText(find.byType(TextField), '48');
    await tester.pump();

    expect(find.byKey(const ValueKey('code-cursor-2')), findsOneWidget);
  });
}
