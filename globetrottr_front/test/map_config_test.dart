import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

void main() {
  setUp(() {
    dotenv.clean();
  });

  tearDown(() {
    dotenv.clean();
  });

  test('falls back to OpenStreetMap tiles when CARTO_API_KEY is not set', () {
    expect(
      MapConfig.tileUrlTemplate,
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );
    expect(MapConfig.tileSubdomains, isEmpty);
  });

  test(
    'uses CARTO tiles with key parameter when CARTO_API_KEY is configured',
    () {
      dotenv.loadFromString(envString: 'CARTO_API_KEY=test_carto_key_123');

      expect(
        MapConfig.tileUrlTemplate,
        'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=test_carto_key_123',
      );
      expect(MapConfig.tileSubdomains, ['a', 'b', 'c', 'd']);
    },
  );
}
