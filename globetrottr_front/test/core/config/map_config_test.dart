import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

void main() {
  group('MapConfig', () {
    tearDown(() {
      dotenv.clean();
    });

    test('uses Carto with the key from dotenv', () {
      dotenv.loadFromString(envString: 'CARTO_API_KEY=env-carto-key');

      expect(
        MapConfig.tileUrlTemplate,
        'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=env-carto-key',
      );
      expect(MapConfig.tileSubdomains, ['a', 'b', 'c', 'd']);
    });

    test('falls back to OpenStreetMap when the key is empty', () {
      dotenv.loadFromString(envString: 'CARTO_API_KEY=');

      expect(
        MapConfig.tileUrlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(MapConfig.tileSubdomains, isEmpty);
    });

    test('falls back to OpenStreetMap when dotenv is not initialized', () {
      dotenv.clean();

      expect(
        MapConfig.tileUrlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(MapConfig.tileSubdomains, isEmpty);
    });
  });
}
