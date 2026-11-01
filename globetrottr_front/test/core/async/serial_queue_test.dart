import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/async/serial_queue.dart';

void main() {
  group('SerialQueue', () {
    test('runs tasks one at a time in the order they were added', () async {
      final queue = SerialQueue();
      final events = <String>[];
      Future<void> task(String name) async {
        events.add('$name start');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        events.add('$name end');
      }

      await Future.wait([
        queue.run(() => task('a')),
        queue.run(() => task('b')),
      ]);

      expect(events, ['a start', 'a end', 'b start', 'b end']);
    });

    test('returns the result of each task to its caller', () async {
      final queue = SerialQueue();

      final first = queue.run(() async => 1);
      final second = queue.run(() async => 'two');

      expect(await first, 1);
      expect(await second, 'two');
    });

    test(
      'a failing task reports its error and does not stop the next',
      () async {
        final queue = SerialQueue();

        final failed = queue.run<int>(() async => throw StateError('boom'));
        final next = queue.run(() async => 2);

        await expectLater(failed, throwsStateError);
        expect(await next, 2);
      },
    );
  });
}
