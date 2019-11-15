import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tflite_native/tflite.dart' as tfl;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_native/tflite.dart';

import 'image_processing.dart';

SendPort sendPort;
List<String> globalLabels;

class DetectionResult {
  final Rect rect;
  final double confidenceInClass;
  final String detectedClass;

  const DetectionResult({
    @required this.rect,
    @required this.confidenceInClass,
    @required this.detectedClass,
  });
}

List<DetectionResult> detectObjectOnFrameSync({
  @required Uint8List imgData,
  @required int numResultsPerClass,
  @required double threshold,
  @required tfl.Interpreter localInterpreter,
  @required List<String> localLabels,
}) {
  final inputTensor = localInterpreter.getInputTensors().single;
  // shape 1, 300, 300, 3; 1 image * 300 width * 300 height * 3 colors
  inputTensor.data = imgData;
  localInterpreter.invoke();
  // https://www.tensorflow.org/lite/models/object_detection/overview
  final outputTensors = localInterpreter.getOutputTensors();

  final outputLocationsTensor = outputTensors[0];
  // shape 1, 10, 4;
  Float32List outputLocations =
      outputLocationsTensor.data.buffer.asFloat32List();

  final outputClassesTensor = outputTensors[1];
  // shape 1, 10
  Float32List outputClasses = outputClassesTensor.data.buffer.asFloat32List();

  final outputScoresTensor = outputTensors[2];
  // shape 1, 10
  Float32List outputScores = outputScoresTensor.data.buffer.asFloat32List();

  final numDetectionsTensor = outputTensors[3];
  // shape 1
  double numDetections = numDetectionsTensor.data.buffer.asFloat32List().single;

  Map<String, int> counters = Map();
  final List<DetectionResult> results = List();
  for (var index = 0; index < numDetections; index++) {
    if (outputScores[index] < threshold) continue;

    String detectedClass = localLabels[outputClasses[index].toInt()];

    if (!counters.containsKey(detectedClass)) {
      counters[detectedClass] = 1;
    } else {
      final count = counters[detectedClass];
      if (count >= numResultsPerClass) {
        continue;
      } else {
        counters[detectedClass] = count + 1;
      }
    }
    final top = max(0.0, outputLocations[index * 4 + 0]);
    final left = max(0.0, outputLocations[index * 4 + 1]);
    final bottom = min(1.0, outputLocations[index * 4 + 2]);
    final right = min(1.0, outputLocations[index * 4 + 3]);

    final thisSesult = DetectionResult(
      rect: Rect.fromLTRB(left, top, right, bottom),
      confidenceInClass: outputScores[index],
      detectedClass: detectedClass,
    );
    results.add(thisSesult);
  }
  return results;
}

class DetectionResultDisplay {
  final List<DetectionResult> detections;
  final Size imageSize;
  final Duration imageProcessingDuration;
  final Duration inferenceDuration;
  final Duration detectionDuration;

  const DetectionResultDisplay({
    @required this.detections,
    @required this.imageSize,
    @required this.imageProcessingDuration,
    @required this.inferenceDuration,
    @required this.detectionDuration,
  });

  static const zero = DetectionResultDisplay(
    detections: [],
    imageSize: Size.zero,
    imageProcessingDuration: Duration.zero,
    inferenceDuration: Duration.zero,
    detectionDuration: Duration.zero,
  );

  Duration get communicationOverhead =>
      detectionDuration - (imageProcessingDuration + inferenceDuration);
}

Future<DetectionResultDisplay> detectObjectOnFrame({
  @required CameraImage camImg,
  @required int numResultsPerClass,
  @required double threshold,
  @required dynamic interpreter,
}) async {
  if (sendPort == null) {
    return DetectionResultDisplay.zero;
  }
  final response = ReceivePort();
  final detectionStartTime = DateTime.now();
  sendPort.send([
    'detect',
    response.sendPort,
    camImg,
    numResultsPerClass,
    threshold,
    interpreter.toSerialized(),
    globalLabels
  ]);
  final resultTuples = await response.first as DetectionResultDisplay;
  final detectionDuration = DateTime.now().difference(detectionStartTime);
  return DetectionResultDisplay(
    detections: resultTuples.detections,
    imageSize: resultTuples.imageSize,
    detectionDuration: detectionDuration,
    imageProcessingDuration: resultTuples.imageProcessingDuration,
    inferenceDuration: resultTuples.inferenceDuration,
  );
}

Future<tfl.Interpreter> loadModel({String model, labels, int numThreads}) async {
  // @todo Future.wait
  final interpreter = await tflInterpreter(model, numThreads: numThreads);
  globalLabels =
      (await rootBundle.loadString('assets/$labels')).split("\n").sublist(1);

  final receivePort = ReceivePort();
  await Isolate.spawn(echo, receivePort.sendPort);

  sendPort = await receivePort.first as SendPort;

  return interpreter;
}

Future<tfl.Interpreter> tflInterpreter(
  String modelFile, {
  int numThreads = 1,
}) async {
  final rawModel = await rootBundle.load('assets/$modelFile');

  Directory appDocDir = await getTemporaryDirectory();
  String appDocPath = appDocDir.path;
  final localFile = File('$appDocPath/$modelFile');
  final raw = rawModel.buffer.asUint8List();
  await localFile.writeAsBytes(raw, flush: true);

  final options = tfl.InterpreterOptions();
  options.threads = numThreads;

  final interpreter =
      tfl.Interpreter.fromFile(localFile.path, options: options);
  interpreter.allocateTensors();
  return interpreter;
}

// the entry point for the isolate
echo(SendPort sendPort) async {
  // Open the ReceivePort for incoming messages.
  final port = ReceivePort();

  // Notify any other isolates what port this isolate listens to.
  sendPort.send(port.sendPort);

  await for (final msg in port) {
    if (msg[0] == 'detect') {
      final replyTo = msg[1] as SendPort;
      final camImage = msg[2] as CameraImage;
      final numResultsPerClass = msg[3] as int;
      final threshold = msg[4] as double;
      final localInterpreter =
          tfl.Interpreter.fromSerialized(msg[5] as tfl.InterpreterSerializable);
      final localLabels = msg[6] as List<String>;

      final imageDetectionStartTime = DateTime.now();
      final processedImage = PreProcessedImageData(camImage);
      final imgData = processedImage.preProccessedImageBytes;
      final imageProcessingEndInferenceStarTime = DateTime.now();

      final result = detectObjectOnFrameSync(
        imgData: imgData,
        numResultsPerClass: numResultsPerClass,
        threshold: threshold,
        localInterpreter: localInterpreter,
        localLabels: localLabels,
      );
      final inferenceEndTime = DateTime.now();
      final imageProcessingDuration = imageProcessingEndInferenceStarTime
          .difference(imageDetectionStartTime);
      final inferenceDuration =
          inferenceEndTime.difference(imageProcessingEndInferenceStarTime);
      replyTo.send(DetectionResultDisplay(
        detections: result,
        imageSize: processedImage.originalSize,
        imageProcessingDuration: imageProcessingDuration,
        inferenceDuration: inferenceDuration,
        detectionDuration: const Duration(microseconds: 0),
      ));
    }
  }
}
