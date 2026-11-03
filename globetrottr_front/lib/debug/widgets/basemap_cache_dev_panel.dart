import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/debug/format_bytes.dart';
import 'package:globetrottr_front/features/map/data/basemap_cache.dart';

/// What the base map cache holds and how much ground that is, for choosing
/// its size limit.
class BasemapCacheDevPanel extends ConsumerStatefulWidget {
  const BasemapCacheDevPanel({super.key});

  static const List<int> limitsInMegabytes = [50, 100, 250, 500, 1000];

  @override
  ConsumerState<BasemapCacheDevPanel> createState() =>
      _BasemapCacheDevPanelState();
}

class _BasemapCacheDevPanelState extends ConsumerState<BasemapCacheDevPanel> {
  static const _mega = 1024 * 1024;

  Timer? _timer;
  BasemapCacheStats? _stats;
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_busy) unawaited(_refresh());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final cache = ref.read(basemapCacheProvider);
    try {
      final stats = await cache.stats();
      if (mounted) setState(() => _stats = stats);
    } on Object catch (error) {
      if (mounted) setState(() => _message = 'Reading failed: $error');
    }
  }

  Future<void> _clear() async {
    final cache = ref.read(basemapCacheProvider);
    setState(() {
      _busy = true;
      _message = 'Clearing...';
    });
    try {
      await cache.clear();
      _message = 'Cleared. Tiles still on screen stay in memory.';
    } on Object catch (error) {
      _message = 'Clearing failed: $error';
    }
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  List<String> _lines(BasemapCacheStats stats, int limit) => [
    'Size: ${formatBytes(stats.totalBytes)} of ${formatBytes(limit)} limit',
    'Vector tiles: ${stats.vectorTiles}, ${formatBytes(stats.vectorBytes)}',
    'Rendered tiles: ${stats.renderedTiles}, ${formatBytes(stats.renderedBytes)}',
    if (stats.otherBytes > 0) 'Other files: ${formatBytes(stats.otherBytes)}',
    _deepestLine(stats),
  ];

  String _deepestLine(BasemapCacheStats stats) {
    final area = stats.deepestZoomAreaKm2.toStringAsFixed(1);
    return 'Full detail (z${MapConfig.basemapMaxZoom}): '
        '${stats.deepestZoomTiles} tiles, $area km2';
  }

  @override
  Widget build(BuildContext context) {
    final limit = ref.watch(basemapCacheLimitProvider);
    final stats = _stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Base map cache', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (stats == null)
          const Text('Reading...')
        else
          for (final line in _lines(stats, limit)) Text(line),
        const SizedBox(height: 8),
        Text(
          'Limit until the app restarts. It is applied a few seconds after a '
          'map is shown, least recently used tiles first. Tiles older than '
          '${MapConfig.basemapCacheTtl.inDays} days are deleted.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final megabytes in BasemapCacheDevPanel.limitsInMegabytes)
              ChoiceChip(
                label: Text('$megabytes MB'),
                selected: limit == megabytes * _mega,
                onSelected: (_) => ref
                    .read(basemapCacheLimitProvider.notifier)
                    .set(megabytes * _mega),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _busy ? null : _clear,
          child: const Text('Clear base map cache'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!),
        ],
      ],
    );
  }
}
