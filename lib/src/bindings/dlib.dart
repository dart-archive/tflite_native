// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;

String _getPlatformLibraryName() {
  if (Platform.isLinux) {
    return 'libtensorflowlite_c-linux.so';
  }

  throw new Exception('Unsupported platform!');
}

/// TensorFlowLite C library.
DynamicLibrary tflitelib = DynamicLibrary.open(
    path.join(Directory.current.path, _getPlatformLibraryName()));
