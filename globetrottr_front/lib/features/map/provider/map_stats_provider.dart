import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How much of the district around the user is discovered.
class AreaProgress {
  const AreaProgress({this.share, this.regionName});

  /// Discovered part, 0 to 1.
  final double? share;
  final String? regionName;
}

// TODO(data): the share of the current district from the bitmap fog and the
// region boundaries, and the district's name.
final areaProgressProvider = Provider<AreaProgress>(
  (ref) => const AreaProgress(),
);

// TODO(data): km² discovered for the first time during the current
// recording, from the bitmap fog.
final sessionNewAreaProvider = Provider<double?>((ref) => null);
