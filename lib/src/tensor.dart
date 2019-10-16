// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';

import 'bindings/tensor.dart';
import 'bindings/types.dart';
import 'ffi/helper.dart';

export 'bindings/types.dart' show TFL_Type;

/// TensorFlowLite tensor.
class Tensor {
  final Pointer<TFL_Tensor> _tensor;

  Tensor(this._tensor) {
    checkNotNull(_tensor);
  }

  /// Name of the tensor element.
  String get name => Utf8.fromUtf8(TFL_TensorName(_tensor));

  /// Data type of the tensor element.
  TFL_Type get type => TFL_TensorType(_tensor);

  /// Dimensions of the tensor.
  List<int> get shape => List.generate(
      TFL_TensorNumDims(_tensor), (i) => TFL_TensorDim(_tensor, i));

  /// Underlying data buffer as bytes.
  List<int> get data {
    final data = cast<Uint8>(TFL_TensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    return UnmodifiableUint8ListView(
        data.asTypedList(TFL_TensorByteSize(_tensor)));
  }

  /// Updates the underlying data buffer with new bytes.
  ///
  /// The size must match the size of the tensor.
  set data(List<int> bytes) {
    final tensorByteSize = TFL_TensorByteSize(_tensor);
    checkArgument(TFL_TensorByteSize(_tensor) == bytes.length);
    final data = cast<Uint8>(TFL_TensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    final externalTypedData = data.asTypedList(tensorByteSize);
    externalTypedData.setRange(0, tensorByteSize, bytes);
  }

  /// Copies the input bytes to the underlying data buffer.
  // TODO(shanehop): Prevent access if unallocated.
  void copyFrom(Uint8List bytes) {
    final size = bytes.length;
    final ptr = allocate<Uint8>(count: size);
    final externalTypedData = ptr.asTypedList(size);
    externalTypedData.setRange(0, bytes.length, bytes);
    checkState(TFL_TensorCopyFromBuffer(_tensor, ptr.cast(), bytes.length) ==
        TFL_Status.ok);
    free(ptr);
  }

  /// Returns a copy of the underlying data buffer.
  // TODO(shanehop): Prevent access if unallocated.
  Uint8List copyTo() {
    int size = TFL_TensorByteSize(_tensor);
    final ptr = allocate<Uint8>(count: size);
    final externalTypedData = ptr.asTypedList(size);
    checkState(
        TFL_TensorCopyToBuffer(_tensor, ptr.cast(), size) == TFL_Status.ok);
    // Clone the data, because once `free(ptr)`, `externalTypedData` will be
    // volatile
    final bytes = externalTypedData.sublist(0);
    free(ptr);
    return bytes;
  }

  // Unimplemented:
  // TFL_TensorQuantizationParams
}
