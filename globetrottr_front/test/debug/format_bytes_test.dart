import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/format_bytes.dart';

void main() {
  group('formatBytes', () {
    test('uses bytes below one kilobyte', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(999), '999 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('uses kilobytes with one decimal', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(500 * 1024), '500.0 KB');
    });

    test('uses megabytes with one decimal', () {
      expect(formatBytes(1024 * 1024), '1.0 MB');
      expect(formatBytes((8.4 * 1024 * 1024).round()), '8.4 MB');
    });

    test('uses gigabytes with two decimals', () {
      expect(formatBytes(1024 * 1024 * 1024), '1.00 GB');
      expect(formatBytes((2.5 * 1024 * 1024 * 1024).round()), '2.50 GB');
    });
  });
}
