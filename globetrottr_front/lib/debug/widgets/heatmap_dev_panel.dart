import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/debug/format_bytes.dart';
import 'package:globetrottr_front/debug/commute_generator.dart';
import 'package:globetrottr_front/debug/heatmap_benchmark.dart';
import 'package:globetrottr_front/features/fog/data/sqflite_fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/heatmap/provider/heatmap_provider.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

/// Diagnostics, tools and the benchmark of the heatmap, for the developer
/// options.
class HeatmapDevPanel extends ConsumerStatefulWidget {
  const HeatmapDevPanel({super.key});

  @override
  ConsumerState<HeatmapDevPanel> createState() => _HeatmapDevPanelState();
}

class _HeatmapDevPanelState extends ConsumerState<HeatmapDevPanel> {
  Timer? _timer;
  int _fileBytes = 0;
  bool _busy = false;
  double? _progress;
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) unawaited(_refreshFile());
    });
    unawaited(_refreshFile());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshFile() async {
    final bytes = await ref.read(heatTileStorageProvider).fileBytes();
    if (mounted) setState(() => _fileBytes = bytes);
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _progress = null;
      _messages
        ..clear()
        ..add('$label...');
    });
    final timer = Stopwatch()..start();
    try {
      await action();
      _messages.add('$label done in ${timer.elapsedMilliseconds} ms.');
    } on Object catch (error) {
      _messages.add('$label failed: $error');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
  }

  void _progressTo(double value) {
    if (mounted) setState(() => _progress = value);
  }

  Future<void> _commutes({required int trips, required int routes}) async {
    // `ref` must not be used after an `await`, so it is read up front.
    final home =
        ref.read(locationProvider).currentPosition ?? MapConfig.initialCenter;
    final fogReady = ref.read(fogProvider.future);
    final fog = ref.read(fogProvider.notifier);
    final heat = ref.read(heatmapProvider.notifier);
    final entries = generateCommutes(
      home: home,
      trips: trips,
      routes: routes,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    await fogReady;
    await fog.importEntries(entries);
    await heat.catchUp(onProgress: _progressTo);
    _messages.add('${entries.length} points in $trips trips.');
  }

  Future<void> _benchmark() async {
    // `ref` must not be used after an `await`, so it is read up front.
    final log = ref.read(trackLogStorageProvider);
    final around =
        ref.read(locationProvider).currentPosition ?? MapConfig.initialCenter;
    final scratch = SqfliteFogTileStorage(fileName: 'heat_benchmark.db');
    try {
      await runHeatmapBenchmark(
        log: log,
        scratch: scratch,
        around: around,
        onLine: (line) {
          debugPrint('HEATMAP BENCH $line');
          if (mounted) setState(() => _messages.add(line));
        },
      );
    } finally {
      await scratch.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final heat = ref.watch(heatmapProvider);
    final lines = <String>[
      'File: heat.db ${formatBytes(_fileBytes)}',
      ...heat.when(
        data: (source) {
          final d = source.store.diagnostics;
          final stats = source.stats;
          final avg = stats.averageMillis.toStringAsFixed(2);
          final max = stats.maxMillis.toStringAsFixed(2);
          final peak = d.peakCachedTiles;
          return [
            'Counted up to log entry ${d.lastAppliedLogId}',
            'Cached tiles: ${d.cachedTiles} (dirty ${d.dirtyTiles}, peak $peak)',
            'Images: ${source.imageCount}, building ${source.pendingBuilds}',
            'Last apply: ${d.lastApplyMicros} us, points ${d.appliedPoints}',
            'Last flush: ${d.lastFlushMillis} ms (${d.lastFlushTiles} tiles)',
            'Paint: avg $avg ms, max $max ms',
          ];
        },
        loading: () => ['Heatmap: opening...'],
        error: (error, _) => ['Heatmap failed: $error'],
      ),
    ];

    final notifier = ref.read(heatmapProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Heatmap', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final line in lines) Text(line),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy || !heat.hasValue
                    ? null
                    : () => _run(
                        'Rebuilding heatmap',
                        () => notifier.rebuild(onProgress: _progressTo),
                      ),
                child: const Text('Rebuild from log'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy || !heat.hasValue
                    ? null
                    : () => _run('Clearing heatmap', notifier.clear),
                child: const Text('Clear heatmap'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : () => _run('Benchmark', _benchmark),
          child: const Text('Run heatmap benchmark'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run('Commutes', () => _commutes(trips: 60, routes: 7)),
          child: const Text('Generate 60 commutes around me'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                  'Heavy traffic',
                  () => _commutes(trips: 300, routes: 30),
                ),
          child: const Text('Generate heavy traffic (300 trips, 30 routes)'),
        ),
        const SizedBox(height: 8),
        if (_busy) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress),
        ],
        for (final message in _messages) Text(message),
      ],
    );
  }
}
