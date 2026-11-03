import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/theme/app_motion.dart';
import 'package:globetrottr_front/core/widgets/animated_column.dart';
import 'package:globetrottr_front/core/widgets/unfold_transition.dart';

void main() {
  Future<void> show(WidgetTester tester, List<String> items) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedColumn(
              spacing: 10,
              children: [
                for (final item in items)
                  SizedBox(key: ValueKey(item), height: 40, child: Text(item)),
              ],
            ),
          ),
        ),
      );

  double heightOf(WidgetTester tester, String item) => tester
      .getSize(
        find
            .ancestor(
              of: find.text(item),
              matching: find.byType(UnfoldTransition),
            )
            .first,
      )
      .height;

  List<String> order(WidgetTester tester) => [
    for (final text in tester.widgetList<Text>(find.byType(Text))) text.data!,
  ];

  testWidgets('a child in place is not clipped, so its shadow shows', (
    tester,
  ) async {
    await show(tester, ['a']);
    await show(tester, ['a', 'b']);
    await tester.pump(AppMotion.standard.medium ~/ 2);

    Clip clipOf(String item) => tester
        .widget<ClipRect>(
          find
              .ancestor(of: find.text(item), matching: find.byType(ClipRect))
              .first,
        )
        .clipBehavior;
    expect(clipOf('b'), isNot(Clip.none));
    expect(clipOf('a'), Clip.none);

    await tester.pumpAndSettle();
    expect(clipOf('b'), Clip.none);
  });

  testWidgets('the first children are there at once', (tester) async {
    await show(tester, ['a', 'b']);

    expect(heightOf(tester, 'a'), 40);
    expect(heightOf(tester, 'b'), 50);
  });

  testWidgets('an added child unfolds with its gap', (tester) async {
    await show(tester, ['a']);
    await show(tester, ['a', 'b']);
    await tester.pump(AppMotion.standard.medium ~/ 2);

    expect(heightOf(tester, 'b'), inExclusiveRange(0, 50));

    await tester.pumpAndSettle();
    expect(heightOf(tester, 'b'), 50);
  });

  group('while the data is appearing', () {
    Future<void> showAppearing(
      WidgetTester tester,
      List<String> items, {
      required bool appearing,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedColumn(
            spacing: 10,
            appearing: appearing,
            children: [
              for (final item in items)
                SizedBox(key: ValueKey(item), height: 40, child: Text(item)),
            ],
          ),
        ),
      ),
    );

    double opacityOf(WidgetTester tester, String item) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: find.text(item), matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    testWidgets('the arriving data fades in at its full size', (tester) async {
      await showAppearing(tester, ['a'], appearing: true);
      await showAppearing(tester, ['a', 'b'], appearing: false);
      await tester.pump(AppMotion.standard.medium ~/ 2);

      expect(heightOf(tester, 'b'), 50);
      expect(opacityOf(tester, 'b'), inExclusiveRange(0, 1));
    });

    testWidgets('a child added once the data is there unfolds', (
      tester,
    ) async {
      await showAppearing(tester, ['a'], appearing: true);
      await showAppearing(tester, ['a', 'b'], appearing: false);
      await tester.pumpAndSettle();
      await showAppearing(tester, ['a', 'b', 'c'], appearing: false);
      await tester.pump(AppMotion.standard.medium ~/ 2);

      expect(heightOf(tester, 'c'), inExclusiveRange(0, 50));
    });
  });

  testWidgets('a removed child folds away in its place', (tester) async {
    await show(tester, ['a', 'b', 'c']);
    await show(tester, ['a', 'c']);
    await tester.pump(AppMotion.standard.medium ~/ 2);

    expect(order(tester), ['a', 'b', 'c']);
    expect(heightOf(tester, 'b'), inExclusiveRange(0, 50));

    await tester.pumpAndSettle();
    expect(order(tester), ['a', 'c']);
  });

  testWidgets('a child put back while folding unfolds again', (tester) async {
    await show(tester, ['a', 'b']);
    await show(tester, ['a']);
    await tester.pump(AppMotion.standard.medium ~/ 2);
    await show(tester, ['a', 'b']);
    await tester.pumpAndSettle();

    expect(order(tester), ['a', 'b']);
    expect(heightOf(tester, 'b'), 50);
  });

  testWidgets('a child keeps its state when others change', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedColumn(
            children: [
              SizedBox(key: ValueKey('a'), height: 40),
              Checkbox.adaptive(
                key: ValueKey('box'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    final box = tester.element(find.byType(Checkbox));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedColumn(
            children: [
              Checkbox.adaptive(
                key: ValueKey('box'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.element(find.byType(Checkbox)), same(box));
  });

  testWidgets('a child can carry a global key', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedColumn(
            children: [SizedBox(key: key, height: 40)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(key.currentContext, isNotNull);
  });

  testWidgets('a child keyed by a number does not clash with a position', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedColumn(
            children: [
              Text('unkeyed'),
              Text('keyed', key: ValueKey(0)),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('unkeyed'), findsOneWidget);
    expect(find.text('keyed'), findsOneWidget);
  });
}
