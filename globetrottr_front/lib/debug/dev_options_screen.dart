import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:globetrottr_front/core/config/map_config.dart';
import 'package:globetrottr_front/debug/offline_simulation_helper.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/features/fog/provider/fog_provider.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';

class DevOptionsScreen extends ConsumerStatefulWidget {
  const DevOptionsScreen({super.key});

  @override
  ConsumerState<DevOptionsScreen> createState() => _DevOptionsScreenState();
}

class _DevOptionsScreenState extends ConsumerState<DevOptionsScreen> {
  int _pendingPointsCount = 0;
  int _pointsToGenerate = 10000;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadPointsCount();
  }

  Future<void> _loadPointsCount() async {
    setState(() => _isLoading = true);
    try {
      final points = await ref.read(mapStorageProvider).getPendingPoints();
      if (!mounted) return;
      setState(() {
        _pendingPointsCount = points.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to load points: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePoints() async {
    final count = _pointsToGenerate;
    final days = math.max(1, count ~/ 2500);

    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating $count points...';
    });

    try {
      final center =
          ref.read(locationProvider).currentPosition ?? MapConfig.initialCenter;
      final points = OfflineSimulationHelper.generatePoints(
        startCenter: center,
        count: count,
        totalDays: days,
      );

      // TODO(fog): simulated points also reach the backend on the next sync
      // and grow the account's server fog and quest progress.
      await ref.read(mapStorageProvider).insertPendingPointsBatch(points);
      await ref.read(fogProvider.future);
      await ref
          .read(fogProvider.notifier)
          .importEntries(OfflineSimulationHelper.toTrackLog(points));
      await _loadPointsCount();

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Generated $count points successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Generation failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPoints() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing database...';
    });

    try {
      await ref.read(mapStorageProvider).clearPendingPoints();
      await _loadPointsCount();

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Database cleared.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to clear: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeksEstimate = (_pointsToGenerate / 7000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Options'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Points in SQLite DB: $_pendingPointsCount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Points to generate: $_pointsToGenerate (~$weeksEstimate weeks of activity)',
            style: const TextStyle(fontSize: 16),
          ),
          Slider(
            min: 500,
            max: 150000,
            divisions: 299,
            value: _pointsToGenerate.toDouble().clamp(500, 150000),
            onChanged: _isLoading
                ? null
                : (value) {
                    setState(() {
                      _pointsToGenerate = (value / 500).round() * 500;
                    });
                  },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _generatePoints,
            child: Text('Generate $_pointsToGenerate Points'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _clearPoints,
                  child: const Text('Clear SQLite DB'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loadPointsCount,
                  child: const Text('Refresh Count'),
                ),
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          const Divider(height: 32),
          const FogDevPanel(),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ],
        ],
      ),
    );
  }
}
