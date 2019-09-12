import 'dart:io';

import 'package:flutter/cupertino.dart';

import 'package:tflite_native/tflite.dart' as tfl;

const MODEL_FILE = "assets/stylize_quantized.pb";
const INPUT_NODE = "input";
const STYLE_NODE = "style_num";
const OUTPUT_NODE = "transformer/expand/conv3/conv/Sigmoid";

class PreviewImage extends StatelessWidget {
  final Future<File> _imageFile;
  final int _styleIndex;
  const PreviewImage(this._imageFile, this._styleIndex, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
        future: _imageFile,
        builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            final inference = tfl.Interpreter.fromFile(MODEL_FILE);
            print(inference.getInputTensors());
            // inference.


            return Image.file(snapshot.data);
          } else if (snapshot.error != null) {
            return const Text(
              'Error picking image.',
              textAlign: TextAlign.center,
            );
          } else {
            return const Text(
              'You have not yet picked an image.',
              textAlign: TextAlign.center,
            );
          }
        });
  }
}
