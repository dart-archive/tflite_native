// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';

import 'bindings/buffer.dart';
import 'bindings/model.dart';
import 'bindings/types.dart';
import 'ffi/helper.dart';

/// TensorFlowLite model.
class Model {
  final Pointer<TfLiteModel> _model;
  bool _deleted = false;

  Pointer<TfLiteModel> get base => _model;

  Model._(this._model);

  /// Loads model from a file or throws if unsuccessful.
  factory Model.fromFile(String path) {
    final cpath = Utf8.toUtf8(path);
    final model = TfLiteModelCreateFromFile(cpath);
    free(cpath);
    checkArgument(isNotNull(model), message: 'Unable to create model.');
    return Model._(model);
  }

  /// Loads model from a file or throws if unsuccessful.
  factory Model.fromByteData(ByteData buffer) {
    final Pointer<Buffer> cBuffer = Buffer.fromByteData(buffer);
    final model = TfLiteNewModel(cBuffer, buffer.buffer.asUint8List().length);
    free(cBuffer);
    checkArgument(isNotNull(model), message: 'Unable to create model.');
    return Model._(model);
  }

  /// Destroys the model instance.
  void delete() {
    checkState(!_deleted, message: 'Model already deleted.');
    TfLiteModelDelete(_model);
    _deleted = true;
  }

  // Unimplemented:
  // Model.fromBuffer => TfLiteNewModel
}
