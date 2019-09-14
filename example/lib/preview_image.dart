import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import 'package:tflite_native/tflite.dart' as tfl;

const MODEL_PREDICT_FILE = "style_predict_quantized_256.tflite";
const MODEL_TRANSFER_FILE = "style_transfer_quantized_dynamic.tflite";
const INPUT_NODE = "input";
const STYLE_NODE = "style_num";
const OUTPUT_NODE = "transformer/expand/conv3/conv/Sigmoid";

class PreviewImage extends StatefulWidget {
  final Future<File> _imageFile;
  final int _styleIndex;
  const PreviewImage(this._imageFile, this._styleIndex, {Key key})
      : super(key: key);

  @override
  _PreviewImageState createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  tfl.Interpreter _stylePredict;
  tfl.Interpreter _styleTransfer;

  @override
  void initState() {
    initInterpreter();
    super.initState();
  }

  void initInterpreter() async {
    final a = await Future.wait([
      tflInterpreter(MODEL_PREDICT_FILE),
      tflInterpreter(MODEL_TRANSFER_FILE),
    ]);
    this.setState(() {
      _stylePredict = a[0];
      _styleTransfer = a[1];
    });
  }

  Future<tfl.Interpreter> tflInterpreter(String modelFile) async {
    final rawModel = await rootBundle.load('assets/tflite/$modelFile');

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    final localFile = File('$appDocPath/$modelFile');
    final raw = rawModel.buffer.asUint8List();
    await localFile.writeAsBytes(raw, flush: true);

    final interpreter = tfl.Interpreter.fromFile(localFile.path);
    interpreter.allocateTensors();
    return interpreter;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _stylePredict?.delete();
    _styleTransfer?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
        future: widget._imageFile?.then((File inputImage) async {
      final bData = await rootBundle
          .load('assets/thumbnails/style${widget._styleIndex}.jpg');
      try {
        return await compute(
            transferStyleSync,
            TransferStyleParams(
                bData,
                _stylePredict.toSerialized(),
                _styleTransfer.toSerialized(),
                inputImage));
      } catch (e) {
        print(e);
      }
    }), builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.data != null) {
        return Image.memory(snapshot.data);
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

class TransferStyleParams {
  final ByteData bData;
  final tfl.InterpreterSerializable stylePredict;
  final tfl.InterpreterSerializable styleTransfer;
  final File inputImage;
  TransferStyleParams(
      this.bData, this.stylePredict, this.styleTransfer, this.inputImage);
}

List<int> transferStyleSync(TransferStyleParams params) {
  final bData = params.bData;
  final _stylePredict = tfl.Interpreter.fromSerialized(params.stylePredict) ;
  final _styleTransfer =  tfl.Interpreter.fromSerialized(params.styleTransfer);
  final inputImage = params.inputImage;

  img.Image image = img.decodeImage(bData.buffer.asUint8List());
  final imageByte = image.getBytes(format: img.Format.rgb);
  final singleData = _stylePredict.getInputTensors().single;
  singleData.data = imageByte; // slow
  _stylePredict.invoke();
  final stylePredictBottle = _stylePredict.getOutputTensors().single; //slow

  img.Image contentImg = img.decodeImage(inputImage.readAsBytesSync()); // slow
  contentImg = img.copyResizeCropSquare(contentImg, 200);
  _styleTransfer.resizeInputTensor(0, [1, 200, 200, 3]); //slow
  _styleTransfer.allocateTensors();

  final styleTransferInputTensors = _styleTransfer.getInputTensors();
  // @todo use copyFrom/To
  styleTransferInputTensors[1].data = stylePredictBottle.data;

  final contentByte = contentImg.getBytes(format: img.Format.rgb);
  Float32List floatData = Float32List(contentByte.length)
    ..setAll(0, contentByte.map((i) => i / 255));
  styleTransferInputTensors[0].data = Uint8List.view(floatData.buffer); //slow

  _styleTransfer.invoke(); // slow

  final output = _styleTransfer.getOutputTensors().single; // slow

  // Get bytes.
  final bytes = Uint8List.fromList(output.data);

  // Get scores (as floats)
  final probabilities = Float32List.view(bytes.buffer);

  final resultRGB = Uint8List(probabilities.length)
    ..setAll(0, probabilities.map((i) => (i * 255).toInt()));

  final blendFactor = 0.8;
  var pixels = contentImg.getBytes();
  for (int i = 0, j = 0, len = pixels.length; i < len; i += 4, j += 3) {
    for (int rgbIndex = 0; rgbIndex < 3; rgbIndex++) {
      final originalPix = pixels[i + rgbIndex];
      final artistPix = resultRGB[j + rgbIndex];
      final newPix = artistPix * blendFactor + originalPix * (1 - blendFactor);
      pixels[i + rgbIndex] = newPix.toInt();
    }
  }
  final processedImageBuff = img.encodeJpg(contentImg);
  return processedImageBuff;
}
