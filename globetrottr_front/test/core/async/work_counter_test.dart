import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/async/work_counter.dart';

void main() {
  late WorkCounter work;
  late bool woke;

  setUp(() {
    work = WorkCounter();
    woke = false;
  });

  Future<void> wait() => work.whenIdle().then((_) => woke = true);

  test('is idle at the start', () async {
    expect(work.isBusy, isFalse);
    await work.whenIdle();
  });

  test('counts the running work', () {
    work
      ..begin()
      ..begin();

    expect(work.count, 2);
    expect(work.isBusy, isTrue);
  });

  test('wakes the waiters only when the last work ends', () async {
    work
      ..begin()
      ..begin();
    final waiting = wait();

    work.end();
    await pumpEventQueue();
    expect(woke, isFalse);

    work.end();
    await waiting;
    expect(woke, isTrue);
    expect(work.isBusy, isFalse);
  });

  test('never counts below zero', () {
    work.end();

    expect(work.count, 0);
  });

  test('release wakes the waiters while work is running', () async {
    work.begin();
    final waiting = wait();

    work.release();

    await waiting;
    expect(woke, isTrue);
  });
}
