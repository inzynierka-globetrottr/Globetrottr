/// A size written the way a person reads it: 999 B, 1.5 KB, 8.4 MB, 2.50 GB.
String formatBytes(int bytes) {
  const kilo = 1024;
  const mega = kilo * 1024;
  const giga = mega * 1024;
  if (bytes < kilo) return '$bytes B';
  if (bytes < mega) return '${(bytes / kilo).toStringAsFixed(1)} KB';
  if (bytes < giga) return '${(bytes / mega).toStringAsFixed(1)} MB';
  return '${(bytes / giga).toStringAsFixed(2)} GB';
}
