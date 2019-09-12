[![Build Status](https://travis-ci.org/dart-lang/tflite_native.svg?branch=master)](https://travis-ci.org/dart-lang/tflite_native)

A Dart interface to [TensorFlow Lite (tflite)](https://www.tensorflow.org/lite) through
Dart's [foreign function interface (FFI)](https://dart.dev/server/c-interop).
This library wraps the experimental tflite
[C API](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/lite/experimental/c/c_api.h).

# Contributing

## Build shared library (`so`) files

Prerequisite: [Bazel build environment](https://www.tensorflow.org/install/source).

- For Android arm64-v8a: `bazel build -c opt --cxxopt=--std=c++11   --crosstool_top=//external:android/crosstool   --host_crosstool_top=@bazel_tools//tools/cpp:toolchain   --cpu=arm64-v8a   //tensorflow/lite/experimental/c:libtensorflowlite_c.so`
- For Android armabi-v7a: `bazel build -c opt --cxxopt=--std=c++11   --crosstool_top=//external:android/crosstool   --host_crosstool_top=@bazel_tools//tools/cpp:toolchain   --cpu=armabi-v7a   //tensorflow/lite/experimental/c:libtensorflowlite_c.so`
- For Linux x64: ...
- For Darwin x64: ...
- For Windows x64: ...
