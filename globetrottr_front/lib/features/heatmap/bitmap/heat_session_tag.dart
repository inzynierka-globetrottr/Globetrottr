/// A 16-bit mark of a session, stored with every counted pixel so a session
/// is counted once however often it passes. It is a hash (FNV-1a), stable
/// across runs and builds, so a replay after a restart recognises the pixels
/// a session already counted. Zero means "never counted".
///
/// Two sessions share a tag with a chance of 1 in 65535; a place they visit
/// one right after the other then counts once.
abstract final class HeatSessionTag {
  static int of(String sessionId) {
    var hash = 0x811C9DC5;
    for (final unit in sessionId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return (hash ^ (hash >> 16)) % 0xFFFF + 1;
  }
}
