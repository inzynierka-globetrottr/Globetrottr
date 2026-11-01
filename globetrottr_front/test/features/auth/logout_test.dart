import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/features/auth/data/auth_service.dart';
import 'package:globetrottr_front/features/auth/provider/auth_provider.dart';
import 'package:globetrottr_front/features/map/data/location_service.dart';
import 'package:globetrottr_front/features/map/data/map_storage.dart';
import 'package:globetrottr_front/features/map/data/pending_point.dart';
import 'package:globetrottr_front/features/map/data/sync_service.dart';

import '../../support/fake_auth_service.dart';
import '../../support/fake_location_service.dart';

class _LoggingOutAuthService extends FakeAuthService {
  int logouts = 0;

  @override
  Future<void> logout() async => logouts++;
}

/// Pending points can be tens of thousands after a long offline trip, so
/// logout must only count them.
class _CountingMapStorage extends MapStorage {
  _CountingMapStorage(this.pending);

  int pending;

  @override
  Future<List<PendingPoint>> getPendingPoints() {
    throw StateError('logout must not load every pending point');
  }

  @override
  Future<int> getPendingPointsCount() async => pending;

  @override
  Future<void> clearPendingPoints() async => pending = 0;
}

void main() {
  late _LoggingOutAuthService auth;
  late FakeSyncService sync;

  ProviderContainer containerWith(_CountingMapStorage storage) {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        syncServiceProvider.overrideWithValue(sync),
        mapStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    auth = _LoggingOutAuthService();
    sync = FakeSyncService();
  });

  test('syncs pending points before logging out', () async {
    final storage = _CountingMapStorage(3);
    final container = containerWith(storage);

    final loggedOut = await container.read(authProvider.notifier).logout();

    expect(loggedOut, isTrue);
    expect(sync.calls, 1);
    expect(storage.pending, 0);
    expect(auth.logouts, 1);
  });

  test('skips the sync when nothing is pending', () async {
    final container = containerWith(_CountingMapStorage(0));

    expect(await container.read(authProvider.notifier).logout(), isTrue);
    expect(sync.calls, 0);
  });

  test('stays logged in when the sync fails', () async {
    sync.succeeds = false;
    final storage = _CountingMapStorage(5);
    final container = containerWith(storage);

    expect(await container.read(authProvider.notifier).logout(), isFalse);
    expect(storage.pending, 5);
    expect(auth.logouts, 0);
  });
}
