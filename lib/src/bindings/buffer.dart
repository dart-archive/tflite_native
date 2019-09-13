// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'dart:typed_data';

/// Represents a (char*) in C memory.
class Buffer extends Struct<Buffer> {
  @Uint8()
  int char;

  /// Allocates and stores the given Dart [String] as a [Pointer<Utf8>].
  static Pointer<Buffer> fromByteData(ByteData byteData) {
    final units = byteData.buffer.asUint8List();
    final ptr = Pointer<Buffer>.allocate(count: units.length);
    units
        .asMap()
        .forEach((i, unit) => ptr.elementAt(i).load<Buffer>().char = unit);
    return ptr;
  }
}
