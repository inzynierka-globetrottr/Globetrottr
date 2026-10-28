import 'dart:async';

/// Runs asynchronous tasks one at a time, in the order they were added.
///
/// A task starts only after the previous one finished, successfully or not,
/// so tasks that read and change shared state never interleave. Each caller
/// gets the result or the error of its own task.
class SerialQueue {
  Future<void> _last = Future.value();

  Future<T> run<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _last = _last.then((_) async {
      try {
        completer.complete(await task());
      } on Object catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}
