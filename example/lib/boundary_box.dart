import 'package:flutter/material.dart';
import 'tflite.dart';

class BoundaryBox extends StatelessWidget {
  final List<DetectionResult> results;
  final Size preview;

  BoundaryBox(this.results, this.preview);

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    List<Widget> _renderBoxes() {
      return results
          .asMap()
          .map((i, re) {
            final color =
                HSLColor.fromAHSL(1, i.toDouble() * 30 + 0, 0.8, 0.5).toColor();
            final Rect displayRect = transformRect(re.rect, preview, screen);

            final widget = Positioned(
              left: displayRect.left,
              top: displayRect.top,
              width: displayRect.width,
              height: displayRect.height,
              child: Container(
                padding: EdgeInsets.only(top: 5.0, left: 5.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color,
                    width: 3.0,
                  ),
                ),
                child: Text(
                  "${re.detectedClass} ${(re.confidenceInClass * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: color,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
            return MapEntry(i, widget);
          })
          .values
          .toList();
    }

    return Stack(
      children: _renderBoxes(),
    );
  }
}

Rect transformRect(Rect inputRect, Size preview, Size screen) {
  final scaleH = screen.width / preview.width * preview.height;
  final scaleW = screen.height / preview.height * preview.width;
  final leftOffset = (screen.width - scaleW) / 2;
  final topOffset = (screen.height - scaleH) / 2;

  final left = inputRect.left * scaleW;
  final top = inputRect.top * scaleH;
  final width = inputRect.width * scaleW;
  final height = inputRect.height * scaleH;

  final rect = Rect.fromLTWH(left, top, width, height)
      .shift(Offset(leftOffset, topOffset));
  return rect;
}
