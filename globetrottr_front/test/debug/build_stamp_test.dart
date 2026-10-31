import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/widgets/build_stamp.dart';

Widget _app(DateTime? installed) {
  return ProviderScope(
    overrides: [appInstalledAtProvider.overrideWith((ref) async => installed)],
    child: const MaterialApp(home: Stack(children: [BuildStamp()])),
  );
}

void main() {
  test('names the install time with leading zeros', () {
    expect(buildStampText(DateTime(2026, 3, 7, 9, 5)), 'APK 07.03 09:05');
  });

  testWidgets('shows when the app was installed', (tester) async {
    await tester.pumpWidget(_app(DateTime(2026, 10, 31, 15, 26)));
    await tester.pump();

    expect(find.text('APK 31.10 15:26'), findsOneWidget);
  });

  testWidgets('shows nothing when the time is unknown', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pump();

    expect(find.byType(Text), findsNothing);
  });
}
