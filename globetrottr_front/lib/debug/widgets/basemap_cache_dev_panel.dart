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

  BasemapCacheStats? _stats;
  String? _status;
  String? _readError;

  /// Reading walks the whole folder, so it runs only when asked and never
  /// alongside clearing, which would let an older scan show stale numbers.
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    unawaited(_settle(_load()));
  }

  void _refresh() {
    setState(() => _busy = true);
    unawaited(_settle(_load()));
  }

  void _clear() {
    setState(() {
      _busy = true;
      _status = 'Clearing...';
    });
    unawaited(_settle(_clearAndLoad()));
  }

  Future<void> _settle(Future<void> work) async {
    await work;
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _load() async {
    try {
      final stats = await ref.read(basemapCacheProvider).stats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _readError = null;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _readError = 'Reading failed: $error');
    }
  }

  Future<void> _clearAndLoad() async {
    String status;
    try {
      await ref.read(basemapCacheProvider).clear();
      status = 'Cleared. Tiles still on screen stay in memory.';
    } on Object catch (error) {
      status = 'Clearing failed: $error';
    }
    if (!mounted) return;
    setState(() => _status = status);
    await _load();
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
          'map is shown, oldest tiles first. Tiles older than '
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
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : _refresh,
              child: const Text('Refresh'),
            ),
            OutlinedButton(
              onPressed: _busy ? null : _clear,
              child: const Text('Clear base map cache'),
            ),
          ],
        ),
        for (final message in [?_readError, ?_status]) ...[
          const SizedBox(height: 8),
          Text(message),
        ],
      ],
    );
  }
}
