import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:globetrottr_front/core/exceptions/silent_image_errors.dart';

void main() {
  late List<FlutterErrorDetails> reported;
  late FlutterExceptionHandler handler;

  setUp(() {
    reported = [];
    handler = skipSilentImageErrors(reported.add);
  });

  test('drops silent image errors, like a cancelled map tile', () {
    handler(
      const FlutterErrorDetails(
        exception: 'Cancelled',
        library: imageResourceServiceLibrary,
        silent: true,
      ),
    );

    expect(reported, isEmpty);
  });

  test('passes image errors that are not silent', () {
    const details = FlutterErrorDetails(
      exception: 'Broken image',
      library: imageResourceServiceLibrary,
    );
    handler(details);

    expect(reported, [details]);
  });

  test('passes silent errors of other libraries', () {
    const details = FlutterErrorDetails(
      exception: 'Something else',
      library: 'widgets library',
      silent: true,
    );
    handler(details);

    expect(reported, [details]);
  });
}
