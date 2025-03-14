import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:camera/camera.dart';

class ObjectDetectionService {
  final ObjectDetector objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  Future<String> detectObjects(CameraImage image) async {
    try {
      final InputImageRotation rotation =
          InputImageRotationValue.fromRawValue(90)!; // อาจต้องปรับค่า rotation ตามกล้อง

      final InputImage inputImage = InputImage.fromBytes(
        bytes: _convertYUV420ToUint8List(image),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<DetectedObject> objects = await objectDetector.processImage(inputImage);
      if (objects.isNotEmpty) {
        return "พบวัตถุ: ${objects.map((e) => e.labels.map((e) => "${e.text} (${e.confidence.toStringAsFixed(2)})").join(", ")).join(", ")}";
      } else {
        return "ไม่พบวัตถุ";
      }
    } catch (e) {
      return "เกิดข้อผิดพลาดในการตรวจจับวัตถุ : $e";
    }
  }

  Uint8List _convertYUV420ToUint8List(CameraImage image) {
    List<int> allBytes = [];
    for (var plane in image.planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  void dispose() {
    objectDetector.close();
  }
}
