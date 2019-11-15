import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;
import 'package:image/image.dart';

class PreProcessedImageData {
  final Size originalSize;
  final Uint8List preProccessedImageBytes;

  PreProcessedImageData._(this.originalSize, this.preProccessedImageBytes);

  factory PreProcessedImageData(CameraImage camImg) {
    final rawRgbImage = convertCameraImageToImageColor(camImg);
    final rgbImage = // camera plugin on Android sucks
        Platform.isAndroid
            ? imglib.copyRotate(
                rawRgbImage,
                90,
              )
            : rawRgbImage;
    return PreProcessedImageData._(
      Size(rgbImage.width.toDouble(), rgbImage.height.toDouble()),
      imglib.copyResizeCropSquare(rgbImage, 300).getBytes(format: Format.rgb),
    );
  }
}

imglib.Image convertCameraImageToImageColor(CameraImage image) {
  if (image.format.group == ImageFormatGroup.bgra8888) {
    return convertBGRA8888toImageColor(image);
  } else if (image.format.group == ImageFormatGroup.yuv420) {
    return convertYUV420toImageColor(image);
  } else {
    throw Exception("unkown format group");
  }
}

imglib.Image convertBGRA8888toImageColor(CameraImage image) {
  final result = imglib.Image.fromBytes(
    image.width,
    image.height,
    image.planes[0].bytes,
    format: imglib.Format.bgra,
  );
  return result;
}

imglib.Image convertYUV420toImageColor(CameraImage image) {
  try {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;

    const alpha255 = (0xFF << 24);

    // imgLib -> Image package from https://pub.dartlang.org/packages/image
    final img = imglib.Image(width, height); // Create Image buffer

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        // Calculate pixel color
        final r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255) as int;
        final g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255) as int;
        final b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255) as int;
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        img.data[index] = alpha255 | (b << 16) | (g << 8) | r;
      }
    }
    return img;
  } catch (e) {
    print('>>>>>>>>>>>> ERROR:' + e.toString());
  }
  return null;
}
