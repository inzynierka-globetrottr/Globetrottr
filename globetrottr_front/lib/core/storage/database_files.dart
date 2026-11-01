import 'dart:io';

/// Everything SQLite keeps on disk next to a database file: the file itself,
/// the write-ahead log with its shared index, and the rollback journal.
const List<String> _databaseFileSuffixes = ['', '-wal', '-shm', '-journal'];

/// Total size in bytes of the database at [path] and its companion files.
/// Zero for a database that does not exist yet or lives in memory.
Future<int> databaseFileBytes(String path) async {
  if (path == ':memory:') return 0;
  var total = 0;
  for (final suffix in _databaseFileSuffixes) {
    final file = File('$path$suffix');
    if (file.existsSync()) total += file.lengthSync();
  }
  return total;
}
