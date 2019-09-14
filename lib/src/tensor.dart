// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';
import 'package:quiver/check.dart';

import 'bindings/tensor.dart';
import 'bindings/types.dart';
import 'bindings/utf8.dart';
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
  Uint8List get data {
    final data = cast<Uint8>(TFL_TensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    return UnmodifiableUint8ListView(
        data.asExternalTypedData(count: TFL_TensorByteSize(_tensor)));
  }

  /// Updates the underlying data buffer with new bytes.
  ///
  /// The size must match the size of the tensor.
  set data(Uint8List bytes) {
    final tensorByteSize = TFL_TensorByteSize(_tensor);
    checkArgument(tensorByteSize == bytes.length);
    final data = cast<Uint8>(TFL_TensorData(_tensor));
    checkState(isNotNull(data), message: 'Tensor data is null.');
    final Uint8List externalTypedData = data.asExternalTypedData(count: tensorByteSize);
    externalTypedData.setRange(0, tensorByteSize, bytes);
  }

  /// Copies the input bytes to the underlying data buffer.
  // TODO(shanehop): Prevent access if unallocated.
  void copyFrom(Uint8List bytes) {
    int size = bytes.length;
    final ptr = Pointer<Uint8>.allocate(count: size);
    final Uint8List externalTypedData = ptr.asExternalTypedData(count: size);
    externalTypedData.setRange(0, bytes.length, bytes);
    checkState(TFL_TensorCopyFromBuffer(_tensor, ptr.cast(), bytes.length) ==
        TFL_Status.ok);
    ptr.free();
  }

  /// Returns a copy of the underlying data buffer.
  // TODO(shanehop): Prevent access if unallocated.
  Uint8List copyTo() {
    int size = TFL_TensorByteSize(_tensor);
    final ptr = Pointer<Uint8>.allocate(count: size);
    final Uint8List externalTypedData = ptr.asExternalTypedData(count: size);
    checkState(TFL_TensorCopyToBuffer(_tensor, ptr.cast(), 4) == TFL_Status.ok);
    // clone the data, because once `ptr.free()`, `externalTypedData` will be volatile
    final bytes = externalTypedData.sublist(0);
    ptr.free();
    return bytes;
  }

  // Unimplemented:
  // TFL_TensorQuantizationParams
}
