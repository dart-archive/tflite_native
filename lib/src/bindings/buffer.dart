// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Represents a (char*) in C memory.
class Buffer extends Struct {
  /// Allocates and stores the given Dart [String] as a [Pointer<Utf8>].
  static Pointer<Buffer> fromByteData(ByteData byteData) {
    final units = byteData.buffer.asUint8List();
    final result = allocate<Uint8>(count: units.length);
    final nativeString = result.asTypedList(units.length);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}
