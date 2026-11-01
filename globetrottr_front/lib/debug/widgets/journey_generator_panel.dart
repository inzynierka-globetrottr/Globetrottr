import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/debug/explorer_journey_import.dart';
import 'package:globetrottr_front/debug/explorer_route_generator.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

/// Kilometres for a slider position in [0, 1]: 1 km to 100 000 km on a
/// logarithmic scale, rounded to 1, 10 or 100 km depending on the size.
int journeyKmForSlider(double t) {
  final km = math.pow(10, 5 * t.clamp(0, 1)).toDouble();
  final step = km < 10 ? 1 : (km < 1000 ? 10 : 100);
  return math.max(1, (km / step).round() * step);
}

/// Developer tool: a synthetic explorer journey written to the track log and
/// drawn into the fog chunk by chunk. It wanders around the current position
/// or crosses a whole continent, from 1 km up to 100 000 km.
class JourneyGeneratorPanel extends ConsumerStatefulWidget {
  const JourneyGeneratorPanel({super.key});

  @override
  ConsumerState<JourneyGeneratorPanel> createState() =>
      _JourneyGeneratorPanelState();
}

class _JourneyGeneratorPanelState extends ConsumerState<JourneyGeneratorPanel> {
  double _slider = 0.6;
  ExplorerRegion? _region;
  bool _running = false;
  bool _stopRequested = false;
  double? _progress;
  String? _message;

  int get _km => journeyKmForSlider(_slider);

  String get _where =>
      _region == null ? 'around my position' : 'across ${_region!.name}';

  Future<void> _generate() async {
    // `ref` must not be used after an `await`, so it is read up front.
    final start =
        ref.read(locationProvider).currentPosition ?? MapConfig.initialCenter;
    final fogReady = ref.read(fogProvider.future);
    final fog = ref.read(fogProvider.notifier);
    final journey = ExplorerJourney(
      start: start,
      totalKm: _km.toDouble(),
      region: _region,
      spacingFollowsSpeed: true,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _running = true;
      _stopRequested = false;
      _progress = 0;
      _message = 'Generating $_km km $_where...';
    });
    final timer = Stopwatch()..start();
    try {
      await fogReady;
      final result = await importJourney(
        journey,
        importChunk: fog.importEntries,
        chunkPoints: 10000,
        isCancelled: () => _stopRequested,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      final seconds = (timer.elapsedMilliseconds / 1000).toStringAsFixed(0);
      _message =
          '${result.cancelled ? 'Stopped after' : 'Generated'} '
          '${result.km.round()} km, ${result.points} points in $seconds s.';
    } on Object catch (error) {
      _message = 'Journey failed: $error';
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journey generator',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Daily trips of motorways, winding roads and city grids, fixes one '
          'second apart, written to the track log and the fog. Large '
          'journeys take a long time and much storage.',
        ),
        DropdownButton<ExplorerRegion?>(
          value: _region,
          onChanged: _running
              ? null
              : (value) => setState(() => _region = value),
          items: [
            const DropdownMenuItem(child: Text('Around my position')),
            for (final region in ExplorerRegion.all)
              DropdownMenuItem(value: region, child: Text(region.name)),
          ],
        ),
        Text('Distance: $_km km'),
        Slider(
          value: _slider,
          onChanged: _running
              ? null
              : (value) => setState(() => _slider = value),
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _running ? null : _generate,
                child: Text('Generate $_km km $_where'),
              ),
            ),
            if (_running) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _stopRequested
                    ? null
                    : () => setState(() => _stopRequested = true),
                child: const Text('Stop'),
              ),
            ],
          ],
        ),
        if (_running) LinearProgressIndicator(value: _progress),
        if (_message != null) Text(_message!),
      ],
    );
  }
}
