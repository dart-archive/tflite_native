import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'boundary_box.dart';
import 'live_view.dart';
import 'tflite.dart';

class HomePage extends StatefulWidget {
  HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription> cameras;
  DetectionResultDisplay _result = DetectionResultDisplay.zero;

  void setRecognitions(DetectionResultDisplay result) {
    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LiveView(setRecognitions),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Pre-processing time: ${_result.imageProcessingDuration.inMilliseconds} ms\n"
                "Inference time: ${_result.inferenceDuration.inMilliseconds} ms \n"
                "Communication overhead: ${_result.communicationOverhead.inMilliseconds} ms \n"
                "Detection time: ${_result.detectionDuration.inMilliseconds} ms \n",
                textAlign: TextAlign.right,
                style: TextStyle(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ),
          BoundaryBox(_result.detections, _result.imageSize),
        ],
      ),
    );
  }
}
