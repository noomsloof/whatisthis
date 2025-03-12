import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;

  DetectionPainter(this.objects, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (var obj in objects) {
      final rect = obj.boundingBox;
      final double scaleX = size.width / imageSize.width;
      final double scaleY = size.height / imageSize.height;

      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      // print("🔲 Bounding Box: $rect -> ปรับขนาดเป็น: $scaledRect");

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
