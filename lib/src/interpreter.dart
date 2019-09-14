// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';
import 'package:quiver/check.dart';

import 'bindings/interpreter.dart';
import 'bindings/types.dart';
import 'interpreter_options.dart';
import 'ffi/helper.dart';
import 'model.dart';
import 'tensor.dart';

class InterpreterSerializable {
  final interpreterAddress;
  final deleted;
  final allocated;

  InterpreterSerializable(this.interpreterAddress, this.deleted, this.allocated);
}
/// TensorFlowLite interpreter for running inference on a model.
class Interpreter {
  final Pointer<TFL_Interpreter> _interpreter;
  bool _deleted = false;
  bool _allocated = false;

  Interpreter._(this._interpreter);
  Interpreter._full(this._interpreter, this._deleted, this._allocated);

  InterpreterSerializable toSerialized() => InterpreterSerializable(_interpreter.address, _deleted, _allocated);

  get unsafeAddress => _interpreter.address;
  get allocated => _allocated;
  factory Interpreter.fromSerialized(InterpreterSerializable serialized) {
    var interpreter = Pointer<TFL_Interpreter>.fromAddress(serialized.interpreterAddress);
    return Interpreter._full(interpreter, serialized.deleted, serialized.allocated);
  }

  /// Creates interpreter from model or throws if unsuccessful.
  factory Interpreter(Model model, {InterpreterOptions options}) {
    final interpreter = TFL_NewInterpreter(
        model.base, options?.base ?? cast<TFL_InterpreterOptions>(nullptr));
    checkArgument(isNotNull(interpreter),
        message: 'Unable to create interpreter.');
    return Interpreter._(interpreter);
  }

  /// Creates interpreter from a model file or throws if unsuccessful.
  factory Interpreter.fromFile(String file, {InterpreterOptions options}) {
    final model = Model.fromFile(file);
    final interpreter = Interpreter(model, options: options);
    model.delete();
    return interpreter;
  }

  /// Creates interpreter from a model file or throws if unsuccessful.
  factory Interpreter.fromByteData(ByteData byteData, {InterpreterOptions options}) {
    final model = Model.fromByteData(byteData); // size 2827952 / 194696096
    final interpreter = Interpreter(model, options: options);
    // model.delete(); // should be delete in `interpreter delete
    return interpreter;
  }

  /// Destroys the model instance.
  void delete() {
    checkState(!_deleted, message: 'Interpreter already deleted.');
    TFL_DeleteInterpreter(_interpreter);
    _deleted = true;
  }

  /// Updates allocations for all tensors.
  void allocateTensors() {
    checkState(!_allocated, message: 'Interpreter already allocated.');
    final status = TFL_InterpreterAllocateTensors(_interpreter);
    checkState(status == TFL_Status.ok);
    _allocated = true;
  }

  /// Runs inference for the loaded graph.
  void invoke() {
    checkState(_allocated, message: 'Interpreter not allocated.');
    checkState(TFL_InterpreterInvoke(_interpreter) == TFL_Status.ok);
  }

  /// Gets all input tensors associated with the model.
  List<Tensor> getInputTensors() => List.generate(
      TFL_InterpreterGetInputTensorCount(_interpreter),
      (i) => Tensor(TFL_InterpreterGetInputTensor(_interpreter, i)),
      growable: false);

  /// Gets all output tensors associated with the model.
  List<Tensor> getOutputTensors() => List.generate(
      TFL_InterpreterGetOutputTensorCount(_interpreter),
      (i) => Tensor(TFL_InterpreterGetOutputTensor(_interpreter, i)),
      growable: false);


  /// Resize input tensor for the given tensor index. `allocateTensors` must be called again afterward.
  void resizeInputTensor(int tensorIndex, List<int> shape) {
    final dimensionSize = shape.length;
    final Pointer<Int32> dimensions = Pointer<Int32>.allocate(count: dimensionSize);
    shape
        .asMap()
        .forEach((i, unit) {
          dimensions.elementAt(i).store(unit);
        });
    final status = TFL_InterpreterResizeInputTensor(_interpreter, tensorIndex, dimensions, dimensionSize);
    dimensions.free();
    checkState(status == TFL_Status.ok);
    _allocated = false;
  }
}
