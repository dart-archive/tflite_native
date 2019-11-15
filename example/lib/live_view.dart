import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_native/tflite.dart';
import 'tflite.dart' as tfl;
import 'dart:math' as math;

typedef void Callback(tfl.DetectionResultDisplay result);

class LiveView extends StatefulWidget {
  final Callback setRecognitions;

  LiveView(this.setRecognitions);

  @override
  _LiveViewState createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  CameraController controller;
  Interpreter interpreter;
  bool isDetecting = false;

  @override
  void initState() {
    _initCamera();
    _initInterpreter();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  void _initInterpreter() async {
    interpreter = await tfl.loadModel(
      model: "ssd_mobilenet.tflite",
      labels: "ssd_mobilenet.txt",
      numThreads: 3,
    );
  }

  void _initCamera() async {
    final cameras = await availableCameras();
    if (cameras == null || cameras.length < 1) {
      print('No camera is found');
      return;
    }
    controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      enableAudio: false,
    );
    await controller.initialize();
    controller.startImageStream((CameraImage camImg) async {
      if (isDetecting) {
        return;
      }
      if (interpreter == null) {
        return;
      }
      isDetecting = true;
      await onCameraImageHandler(camImg, interpreter, widget.setRecognitions);
      isDetecting = false;
    });

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    interpreter?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: RaisedButton(
          onPressed: _initCamera,
          child: Text("No camera available. Tap to retry!"),
        ),
      );
    }

    var tmp = MediaQuery.of(context).size;
    final screenH = math.max(tmp.height, tmp.width);
    final screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    final previewH = math.max(tmp.height, tmp.width);
    final previewW = math.min(tmp.height, tmp.width);
    final screenRatio = screenH / screenW;
    final previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
  }
}

Future<void> onCameraImageHandler(
  CameraImage camImg,
  Interpreter interpreter,
  Callback setRecognitions,
) async {
  final recognitions = await tfl.detectObjectOnFrame(
    camImg: camImg,
    numResultsPerClass: 5,
    threshold: 0.4,
    interpreter: interpreter,
  );
  setRecognitions(recognitions);
}
