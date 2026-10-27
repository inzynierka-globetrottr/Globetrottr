import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/debug/widgets/fog_dev_panel.dart';
import 'package:globetrottr_front/features/fog/data/fog_tile_storage.dart';
import 'package:globetrottr_front/features/map/data/track_log_storage.dart';

import '../support/fake_location_service.dart';

class _SlowStorage extends InMemoryFogTileStorage {
  final Completer<void> gate = Completer<void>();

  @override
  Future<FogStorageStats> stats() async {
    await gate.future;
    return super.stats();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('leaving the screen while storage is read does not crash', (
    tester,
  ) async {
    final storage = _SlowStorage();
    final env = FogTestEnvironment(tiles: storage);
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    storage.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the storage figures once they are read', (tester) async {
    final env = FogTestEnvironment();
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.textContaining('Track log points: 0'), findsOneWidget);
    expect(find.textContaining('Tiles on disk: 0'), findsOneWidget);
  });

  testWidgets('shows the size of both database files', (tester) async {
    final env = FogTestEnvironment();
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(
      find.textContaining('Files: fog.db 0 B, tracks.db 0 B, total 0 B'),
      findsOneWidget,
    );
  });

  testWidgets('adds up the files and writes the sizes readably', (
    tester,
  ) async {
    final env = FogTestEnvironment(
      tiles: _SizedTiles(8 * 1024 * 1024),
      log: _SizedLog(1536),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: FogDevPanel())),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(
      find.textContaining(
        'Files: fog.db 8.0 MB, tracks.db 1.5 KB, total 8.0 MB',
      ),
      findsOneWidget,
    );
  });
}

class _SizedTiles extends InMemoryFogTileStorage {
  _SizedTiles(this.size);

  final int size;

  @override
  Future<int> fileBytes() async => size;
}

class _SizedLog extends InMemoryTrackLogStorage {
  _SizedLog(this.size);

  final int size;

  @override
  Future<int> fileBytes() async => size;
}
