import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/localization/area_format.dart';

void main() {
  test('uses the decimal separator of the language', () {
    expect(formatKm2(0.92, 'pl'), '0,92');
    expect(formatKm2(0.92, 'en'), '0.92');
  });

  test('keeps the requested number of decimals', () {
    expect(formatKm2(15.2, 'pl', decimals: 1), '15,2');
    expect(formatKm2(3, 'pl', decimals: 1), '3,0');
  });

  test('an unknown area is a dash', () {
    expect(formatKm2(null, 'pl'), '—');
  });
}
