import 'dart:async';

/// Counts work in progress and tells when none is left.
class WorkCounter {
  int _count = 0;
  final List<Completer<void>> _waiters = [];

  int get count => _count;

  bool get isBusy => _count > 0;

  void begin() => _count++;

  /// Ends one piece of work and wakes the [whenIdle] callers if it was the
  /// last one.
  void end() {
    if (_count > 0) _count--;
    if (_count == 0) release();
  }

  /// Completes when no work is running.
  Future<void> whenIdle() {
    if (_count == 0) return Future.value();
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  /// Wakes every [whenIdle] caller now, for when the owner shuts down.
  void release() {
    final waiters = List.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      waiter.complete();
    }
  }
}
