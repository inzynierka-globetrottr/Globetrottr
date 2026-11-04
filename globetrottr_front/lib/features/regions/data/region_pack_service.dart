import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:globetrottr_front/core/async/serial_queue.dart';
import 'package:globetrottr_front/features/regions/data/region_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Installs a country's cities and districts from the app bundle the first
/// time the user records there, so only visited countries take disk space
/// twice. No network is involved.
class RegionPackService {
  RegionPackService({
    required this.storage,
    Future<ByteData> Function(String assetPath)? loadAsset,
    Future<String> Function()? tempDir,
  }) : _loadAsset = loadAsset ?? rootBundle.load,
       _tempDir = tempDir ?? getDatabasesPath;

  static const _folder = 'assets/data/regions';

  final RegionStorage storage;
  final Future<ByteData> Function(String assetPath) _loadAsset;
  final Future<String> Function() _tempDir;
  final SerialQueue _queue = SerialQueue();
  Map<String, Object?>? _index;

  /// True when the country's file was installed now; false when it already
  /// was at the bundled version, when the country has no file, or when the
  /// install failed.
  Future<bool> ensurePack(String countryCode) =>
      _queue.run(() => _ensure(countryCode));

  Future<bool> _ensure(String countryCode) async {
    try {
      final index = _index ??= await _readIndex();
      final version = index['version']! as int;
      final packs = (index['packs']! as List).cast<Map<String, Object?>>();
      final entry = packs.where((e) => e['country'] == countryCode).firstOrNull;
      if (entry == null) return false;
      final installed = await storage.installedPacks();
      if (installed[countryCode] == version) return false;

      final data = await _loadAsset('$_folder/${entry['file']}');
      final file = File(p.join(await _tempDir(), 'pack_$countryCode.db'));
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      try {
        await storage.installPack(countryCode, version, file.path);
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
      return true;
    } catch (e) {
      debugPrint('Installing the regions of $countryCode failed: $e');
      return false;
    }
  }

  Future<Map<String, Object?>> _readIndex() async {
    final data = await _loadAsset('$_folder/index.json');
    return jsonDecode(
          utf8.decode(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          ),
        )
        as Map<String, Object?>;
  }
}
