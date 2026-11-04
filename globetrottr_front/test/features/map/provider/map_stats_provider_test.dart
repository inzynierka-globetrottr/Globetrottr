import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:globetrottr_front/core/time/clock.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';
import 'package:globetrottr_front/features/map/data/track_log_entry.dart';
import 'package:globetrottr_front/features/map/provider/location_provider.dart';
import 'package:globetrottr_front/features/map/provider/map_stats_provider.dart';
import 'package:globetrottr_front/features/quests/data/quest_service.dart';
import 'package:globetrottr_front/features/regions/data/region.dart';
import 'package:globetrottr_front/features/regions/data/region_type.dart';
import 'package:globetrottr_front/features/regions/data/sqflite_region_storage.dart';
import 'package:globetrottr_front/features/statistics/data/sqflite_statistics_storage.dart';
import 'package:globetrottr_front/features/statistics/data/user_region_stats.dart';
import 'package:globetrottr_front/features/statistics/logic/statistics_tracker.dart';
import 'package:globetrottr_front/features/statistics/provider/statistics_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../test/support/fake_location_service.dart';

class _RecordingDays extends Fake implements StatisticsTracker {
  final days = <DateTime>[];

  @override
  Future<void> recordRecordingDay({DateTime? now}) async => days.add(now!);

  @override
  Future<void> recordTripSession({
    required double distanceM,
    required int durationSeconds,
    required String activityType,
    double? maxAltitudeM,
    DateTime? now,
  }) async {}

  @override
  Future<void> onTilesCommitted(
    Iterable<TileAreaDelta> tiles, {
    DateTime? now,
  }) async {}
}

TrackLogEntry _fix(double northMeters) => TrackLogEntry(
  sessionId: 's',
  timestampMs: 0,
  latitude: 50.06 + northMeters / 111319.9,
  longitude: 19.94,
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MapStatsProvider', () {
    late Directory tempDir;
    late SqfliteRegionStorage regionStorage;
    late SqfliteStatisticsStorage statsStorage;
    late FakeLocationService fakeLocationService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('map_stats_test_');
      regionStorage = SqfliteRegionStorage(
        path: '${tempDir.path}/regions.db',
        autoSeed: false,
      );
      await regionStorage.init();

      statsStorage = SqfliteStatisticsStorage(path: '${tempDir.path}/stats.db');
      await statsStorage.init();

      fakeLocationService = FakeLocationService();
    });

    tearDown(() async {
      await regionStorage.close();
      await statsStorage.close();
      await tempDir.delete(recursive: true);
    });

    test(
      'AreaProgressNotifier resolves region and share from position',
      () async {
        const krakow = Region(
          id: 1001,
          parentId: null,
          name: 'Kraków',
          type: RegionType.city,
          code: null,
          totalAreaKm2: 326.8,
          minLat: 49.97,
          maxLat: 50.13,
          minLon: 19.79,
          maxLon: 20.22,
        );
        await regionStorage.insertRegions([krakow]);

        await statsStorage.saveRegionStats([
          const UserRegionStats(
            regionId: 1001,
            discoveredAreaM2: 32680000.0,
            discoveryPercentage: 10.0,
            firstVisitMs: 1000,
            lastVisitMs: 2000,
          ),
        ]);

        final container = ProviderContainer(
          overrides: [
            regionStorageProvider.overrideWithValue(regionStorage),
            statisticsStorageProvider.overrideWithValue(statsStorage),
            locationServiceProvider.overrideWithValue(fakeLocationService),
            syncServiceProvider.overrideWithValue(FakeSyncService()),
          ],
        );
        addTearDown(container.dispose);
        container.listen(areaProgressProvider, (_, __) {});

        // Initially no location
        final initial = container.read(areaProgressProvider);
        expect(initial.regionName, isNull);
        expect(initial.share, isNull);

        // Simulate location update to Kraków
        await container.read(locationProvider.notifier).startTracking();
        fakeLocationService.positions.add(
          Position(
            latitude: 50.0614,
            longitude: 19.9366,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 200.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 1.0,
            speedAccuracy: 1.0,
          ),
        );

        // Allow async region resolution to complete
        for (var i = 0; i < 50; i++) {
          if (container.read(areaProgressProvider).regionName != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        final progress = container.read(areaProgressProvider);
        expect(progress.regionName, 'Kraków');
        expect(progress.share, closeTo(0.10, 0.001));
      },
    );

    test(
      'SessionNewAreaNotifier starts at 0.0 when recording and accumulates area',
      () async {
        final container = ProviderContainer(
          overrides: [
            regionStorageProvider.overrideWithValue(regionStorage),
            statisticsStorageProvider.overrideWithValue(statsStorage),
            locationServiceProvider.overrideWithValue(fakeLocationService),
            syncServiceProvider.overrideWithValue(FakeSyncService()),
            questServiceProvider.overrideWithValue(FakeQuestService()),
          ],
        );
        addTearDown(container.dispose);
        container.listen(areaProgressProvider, (_, __) {});

        expect(container.read(sessionNewAreaProvider), isNull);

        // Start recording
        await container.read(locationProvider.notifier).setRecording(true);
        expect(container.read(sessionNewAreaProvider), 0.0);

        // Add area delta (50,000 m2 = 0.05 km2)
        container.read(sessionNewAreaProvider.notifier).addAreaM2(50000.0);
        expect(container.read(sessionNewAreaProvider), closeTo(0.05, 0.0001));

        // Stop recording resets to null
        await container.read(locationProvider.notifier).setRecording(false);
        expect(container.read(sessionNewAreaProvider), isNull);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );

    group('recording days', () {
      late _RecordingDays tracker;
      late DateTime now;

      ProviderContainer recordingContainer() {
        final container = ProviderContainer(
          overrides: <Override>[
            regionStorageProvider.overrideWithValue(regionStorage),
            statisticsStorageProvider.overrideWithValue(statsStorage),
            locationServiceProvider.overrideWithValue(fakeLocationService),
            syncServiceProvider.overrideWithValue(FakeSyncService()),
            questServiceProvider.overrideWithValue(FakeQuestService()),
            statisticsTrackerProvider.overrideWithValue(tracker),
            clockProvider.overrideWithValue(() => now),
          ],
        );
        addTearDown(container.dispose);
        container.listen(sessionNewAreaProvider, (_, _) {});
        return container;
      }

      setUp(() {
        tracker = _RecordingDays();
        now = DateTime(2026, 11, 3, 14);
      });

      test(
        '150 m of recording counts the day before recording stops',
        () async {
          final container = recordingContainer();
          await container.read(locationProvider.notifier).setRecording(true);

          fakeLocationService.logged.add(_fix(0));
          fakeLocationService.logged.add(_fix(150));
          await pumpEventQueue();

          expect(tracker.days, [now]);
        },
      );

      test('new area alone counts the day', () async {
        final container = recordingContainer();
        await container.read(locationProvider.notifier).setRecording(true);

        container.read(sessionNewAreaProvider.notifier).addAreaM2(500);
        await pumpEventQueue();

        expect(tracker.days, hasLength(1));
      });

      test('a recording across midnight counts both days', () async {
        final container = recordingContainer();
        now = DateTime(2026, 11, 3, 23, 50);
        await container.read(locationProvider.notifier).setRecording(true);
        fakeLocationService.logged.add(_fix(0));
        fakeLocationService.logged.add(_fix(150));
        await pumpEventQueue();

        now = DateTime(2026, 11, 4, 0, 20);
        fakeLocationService.logged.add(_fix(300));
        await pumpEventQueue();

        expect(
          tracker.days.map((d) => (d.year, d.month, d.day)).toList(),
          [(2026, 11, 3), (2026, 11, 4)],
        );
      });
    });
  });
}
