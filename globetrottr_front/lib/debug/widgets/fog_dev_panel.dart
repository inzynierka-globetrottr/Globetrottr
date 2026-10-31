import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/debug/format_bytes.dart';
import 'package:globetrottr_front/debug/widgets/recorded_points_layer.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/fog/fog_config.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/fog/render/fog_render_options.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

/// Diagnostics and test tools of the bitmap fog, for the developer options.
class FogDevPanel extends ConsumerStatefulWidget {
  const FogDevPanel({super.key});

  @override
  ConsumerState<FogDevPanel> createState() => _FogDevPanelState();
}

class _FogDevPanelState extends ConsumerState<FogDevPanel> {
  Timer? _timer;
  FogStorageStats? _storage;
  int _fogFileBytes = 0;
  int _trackFileBytes = 0;
  int _logPoints = 0;
  int _ticks = 0;
  bool _busy = false;
  double? _progress;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshStorage());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (++_ticks % 3 == 0) unawaited(_refreshStorage());
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStorage() async {
    // `ref` must not be used after an `await` because the screen can be left
    // meanwhile, so everything needed is read from it up front.
    final tiles = ref.read(fogTileStorageProvider);
    final log = ref.read(trackLogStorageProvider);
    final stats = await tiles.stats();
    final count = await log.count();
    final fogBytes = await tiles.fileBytes();
    final trackBytes = await log.fileBytes();
    if (!mounted) return;
    setState(() {
      _storage = stats;
      _logPoints = count;
      _fogFileBytes = fogBytes;
      _trackFileBytes = trackBytes;
    });
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _progress = null;
      _message = '$label...';
    });
    final timer = Stopwatch()..start();
    try {
      await action();
      _message = '$label done in ${timer.elapsedMilliseconds} ms.';
    } on Object catch (error) {
      _message = '$label failed: $error';
    }
    await _refreshStorage();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
    });
  }

  /// What the two databases really take on the phone, journals included.
  String _filesLine() {
    final total = _fogFileBytes + _trackFileBytes;
    return 'Files: fog.db ${formatBytes(_fogFileBytes)}, '
        'tracks.db ${formatBytes(_trackFileBytes)}, '
        'total ${formatBytes(total)}';
  }

  String _storageLine(FogStorageStats storage) {
    final base = storage.tilesPerLevel[FogConfig.baseZoom] ?? 0;
    return 'Tiles on disk: ${storage.tileCount} (base $base), '
        'payload ${formatBytes(storage.totalBytes)}';
  }

  void _updateOptions(FogRenderOptions Function(FogRenderOptions) change) {
    final notifier = ref.read(fogRenderOptionsProvider.notifier);
    notifier.options = change(notifier.options);
  }

  @override
  Widget build(BuildContext context) {
    final fog = ref.watch(fogProvider);
    final options = ref.watch(fogRenderOptionsProvider);
    final storage = _storage;

    final lines = <String>[
      if (storage != null) _storageLine(storage),
      'Track log points: $_logPoints',
      _filesLine(),
      ...fog.when(
        data: (source) {
          final d = source.store.diagnostics;
          final stats = source.stats;
          final area = (d.totalAreaM2 / 1e6).toStringAsFixed(3);
          final avg = stats.averageMillis.toStringAsFixed(2);
          final max = stats.maxMillis.toStringAsFixed(2);
          return [
            'Discovered: $area km2, revision ${d.revision}',
            'Cached tiles: ${d.cachedTiles} (dirty ${d.dirtyTiles})',
            'Images: ${source.imageCount}, building ${source.pendingBuilds}',
            'Last apply: ${d.lastApplyMicros} us, points ${d.appliedPoints}',
            'Last flush: ${d.lastFlushMillis} ms (${d.lastFlushTiles} tiles)',
            'Paint: avg $avg ms, max $max ms (${stats.frames} frames)',
            if (d.skippedLogEntries > 0)
              'Skipped log entries: ${d.skippedLogEntries} (rebuild to redraw)',
          ];
        },
        loading: () => ['Fog is loading...'],
        error: (error, _) => ['Fog failed to load: $error'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bitmap fog', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final line in lines) Text(line),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Soft fog edge'),
          value: options.softEdge,
          onChanged: (value) =>
              _updateOptions((o) => o.copyWith(softEdge: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show recorded points'),
          subtitle: const Text(
            'Pink dots are the GPS fixes stored in the track log, blue lines '
            'join consecutive fixes. Everything the fog reveals between them '
            'is interpolation. Visible from zoom 14',
          ),
          value: ref.watch(recordedPointsVisibleProvider),
          onChanged: (value) => ref
              .read(recordedPointsVisibleProvider.notifier)
              .set(visible: value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Raw fog pixels'),
          subtitle: const Text(
            'The stored pixels as they are: no blur, no smoothing, no live '
            'fog. Zoom in to see the lines between pixels',
          ),
          value: options.rawPixels,
          onChanged: (value) =>
              _updateOptions((o) => o.copyWith(rawPixels: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show tile grid'),
          subtitle: const Text(
            'Outlines the drawn tiles: green has fog data, grey is empty, '
            'orange is loading',
          ),
          value: options.showGrid,
          onChanged: (value) =>
              _updateOptions((o) => o.copyWith(showGrid: value)),
        ),
        Text('Soft edge width: ${options.softEdgeMeters.toStringAsFixed(1)} m'),
        Slider(
          max: 12,
          value: options.softEdgeMeters.clamp(0, 12),
          onChanged: (value) =>
              _updateOptions((o) => o.copyWith(softEdgeMeters: value)),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run('Rebuilding fog', () async {
                        await ref.read(fogProvider.future);
                        await ref
                            .read(fogProvider.notifier)
                            .rebuild(
                              onProgress: (v) {
                                if (mounted) setState(() => _progress = v);
                              },
                            );
                      }),
                child: const Text('Rebuild from log'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run('Clearing fog', () async {
                        await ref.read(fogProvider.future);
                        await ref.read(fogProvider.notifier).clearFog();
                      }),
                child: const Text('Clear fog'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run('Clearing track log', () async {
                  await ref.read(trackLogStorageProvider).clear();
                }),
          child: const Text('Clear track log (cannot be rebuilt)'),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress),
        ],
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!),
        ],
      ],
    );
  }
}
