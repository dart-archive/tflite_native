[![Build Status](https://github.com/dart-lang/tflite_native/workflows/Dart/badge.svg)](https://github.com/dart-lang/tflite_native/actions)

## Status

Note, this package has been **discontinued** - no support or maintenance is
planned.

## What is it?

A Dart interface to [TensorFlow Lite (tflite)](https://www.tensorflow.org/lite)
through Dart's
[foreign function interface (FFI)](https://dart.dev/server/c-interop).
This library wraps the experimental tflite
[C API](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/lite/experimental/c/c_api.h).

## What Dart platforms does this package support?

This package supports desktop use cases (Linux, OSX, Windows, etc). 

## What if I want TensorFlow Lite support for Flutter apps?

Flutter developers should instead
consider using the Flutter plugin [flutter_tflite](https://github.com/shaqian/flutter_tflite)
(among the issues using this package with Flutter, we locate the tflite dynamic library through
`Isolate.resolvePackageUri`, which doesn't translate perfectly in the Flutter context (see
https://github.com/flutter/flutter/issues/14815).
