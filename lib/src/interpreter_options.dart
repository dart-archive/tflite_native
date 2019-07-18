import 'dart:ffi';
import 'package:quiver/check.dart';

import 'bindings/interpreter_options.dart';
import 'bindings/types.dart';

/// TensorFlowLite interpreter options.
class InterpreterOptions {
  final Pointer<TFL_InterpreterOptions> _options;
  bool _deleted = false;

  Pointer<TFL_InterpreterOptions> get base => _options;

  InterpreterOptions._(this._options);

  /// Creates a new options instance.
  factory InterpreterOptions() =>
      InterpreterOptions._(TFL_NewInterpreterOptions());

  /// Destroys the options instance.
  void delete() {
    checkState(!_deleted, message: 'InterpreterOptions already deleted.');
    TFL_DeleteInterpreterOptions(_options);
    _deleted = true;
  }

  /// Sets the number of CPU threads to use.
  set threads(int threads) =>
      TFL_InterpreterOptionsSetNumThreads(_options, threads);

  // Unimplemented:
  // TFL_InterpreterOptionsSetErrorReporter
}
