// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Wraps a model interpreter.
class TFL_Interpreter extends Struct {}

/// Wraps customized interpreter configuration options.
class TFL_InterpreterOptions extends Struct {}

/// Wraps a loaded TensorFlowLite model.
class TFL_Model extends Struct {}

/// Wraps data associated with a graph tensor.
class TFL_Tensor extends Struct {}

/// Status of a TensorFlowLite function call.
class TFL_Status {
  static const ok = 0;
  static const error = 1;
}

/// Types supported by tensor.
enum TFL_Type {
  none,
  float32,
  int32,
  uint8,
  int64,
  string,
  bool,
  int16,
  complex64,
  int8,
  float16
}
