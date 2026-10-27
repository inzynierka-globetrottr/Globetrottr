import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/config/dev_config.dart';

void main() {
  group('DevConfig', () {
    tearDown(() {
      dotenv.clean();
    });

    test('isDevMode returns false when not set in environment or dotenv', () {
      dotenv.clean();
      expect(DevConfig.isDevMode, isFalse);
    });

    test('isDevMode returns true when DEV_MODE=true in dotenv', () {
      dotenv.loadFromString(envString: 'DEV_MODE=true');
      expect(DevConfig.isDevMode, isTrue);
    });

    test('isDevMode returns true when ENABLE_DEV_SCREEN=true in dotenv', () {
      dotenv.loadFromString(envString: 'ENABLE_DEV_SCREEN=true');
      expect(DevConfig.isDevMode, isTrue);
    });

    test('isDevMode returns false when DEV_MODE=false in dotenv', () {
      dotenv.loadFromString(envString: 'DEV_MODE=false');
      expect(DevConfig.isDevMode, isFalse);
    });

    test(
      'isDevMode returns false when DEV_MODE is 1 or any non-true string',
      () {
        dotenv.loadFromString(envString: 'DEV_MODE=1');
        expect(DevConfig.isDevMode, isFalse);

        dotenv.loadFromString(envString: 'DEV_MODE=yes');
        expect(DevConfig.isDevMode, isFalse);
      },
    );
  });
}
