// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Throws an [ArgumentError] if [test] is false.
void checkArgument(bool test, {String message}) {
  if (!test) throw ArgumentError(message);
}

/// Throws a [StateError] if [test] is false.
void checkState(bool test, {String message}) {
  if (!test) throw StateError(message ?? 'failed precondition');
}
