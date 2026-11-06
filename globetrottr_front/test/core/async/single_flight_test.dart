import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/async/single_flight.dart';

void main() {
  test('a call while the same key is running is dropped', () async {
    final flight = SingleFlight<String>();
    final release = Completer<void>();
    var runs = 0;

    final first = flight.run('ola', () async {
      runs++;
      await release.future;
    });
    await flight.run('ola', () async => runs++);
    expect(runs, 1);
    expect(flight.isRunning('ola'), isTrue);

    release.complete();
    await first;
    expect(flight.isRunning('ola'), isFalse);
  });

  test('other keys run at the same time', () async {
    final flight = SingleFlight<String>();
    final release = Completer<void>();
    final started = <String>[];

    final first = flight.run('ola', () async {
      started.add('ola');
      await release.future;
    });
    await flight.run('kuba', () async => started.add('kuba'));

    expect(started, ['ola', 'kuba']);
    release.complete();
    await first;
  });

  test('a key runs again once its action has ended', () async {
    final flight = SingleFlight<String>();
    var runs = 0;

    await flight.run('ola', () async => runs++);
    await flight.run('ola', () async => runs++);

    expect(runs, 2);
  });

  test('a failure reaches its caller and frees the key', () async {
    final flight = SingleFlight<String>();

    await expectLater(
      flight.run('ola', () async => throw StateError('offline')),
      throwsStateError,
    );
    expect(flight.isRunning('ola'), isFalse);

    var ran = false;
    await flight.run('ola', () async => ran = true);
    expect(ran, isTrue);
  });
}
