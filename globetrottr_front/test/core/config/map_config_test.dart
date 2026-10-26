import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/map_config.dart';

void main() {
  group('MapConfig', () {
    tearDown(() {
      dotenv.clean();
    });

    test(
      'buildTileUrlTemplate includes key query param when apiKey is provided',
      () {
        final url = MapConfig.buildTileUrlTemplate(apiKey: 'sample-carto-key');

        expect(
          url,
          equals(
            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=sample-carto-key',
          ),
        );
      },
    );

    test('buildTileUrlTemplate trims apiKey whitespace', () {
      final url = MapConfig.buildTileUrlTemplate(
        apiKey: '  sample-carto-key  ',
      );

      expect(
        url,
        equals(
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=sample-carto-key',
        ),
      );
    });

    test(
      'buildTileUrlTemplate returns base URL without query param when apiKey is null or empty',
      () {
        expect(
          MapConfig.buildTileUrlTemplate(),
          equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'),
        );
        expect(
          MapConfig.buildTileUrlTemplate(apiKey: ''),
          equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'),
        );
        expect(
          MapConfig.buildTileUrlTemplate(apiKey: '   '),
          equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'),
        );
      },
    );

    test('tileUrlTemplate reads CARTO_API_KEY from dotenv when initialized', () {
      dotenv.loadFromString(envString: 'CARTO_API_KEY=env-carto-key');

      expect(
        MapConfig.tileUrlTemplate,
        equals(
          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=env-carto-key',
        ),
      );
    });

    test(
      'tileUrlTemplate returns base URL gracefully when dotenv is not initialized',
      () {
        dotenv.clean();

        expect(
          MapConfig.tileUrlTemplate,
          equals('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'),
        );
      },
    );
  });
}
