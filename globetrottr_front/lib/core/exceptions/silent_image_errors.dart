import 'package:flutter/foundation.dart';

/// The library Flutter names in errors of image loading.
const imageResourceServiceLibrary = 'image resource service';

/// Wraps [next] so it drops image errors reported as silent.
///
/// The map tile layer reports a tile whose loading it cancelled, for example
/// after a zoom change, as a silent image error. A release build never shows
/// silent errors, but a debug build prints each of them, which floods the
/// console while zooming; this keeps a debug build as quiet as a release one.
FlutterExceptionHandler skipSilentImageErrors(FlutterExceptionHandler? next) =>
    (details) {
      if (details.silent && details.library == imageResourceServiceLibrary) {
        return;
      }
      next?.call(details);
    };
