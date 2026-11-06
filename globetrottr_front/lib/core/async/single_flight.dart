/// Runs at most one action per key at a time. A call for a key whose action
/// is still running is dropped, so a button tapped again while its request
/// is on the way sends nothing more.
class SingleFlight<K> {
  final Set<K> _running = {};

  bool isRunning(K key) => _running.contains(key);

  /// Completes when the action ends, with its error if it failed; a dropped
  /// call completes at once.
  Future<void> run(K key, Future<void> Function() action) async {
    if (!_running.add(key)) return;
    try {
      await action();
    } finally {
      _running.remove(key);
    }
  }
}
