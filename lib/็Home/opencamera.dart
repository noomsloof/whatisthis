import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:typed_data';

import 'package:whatisthis/%E0%B9%87Home/detectionPainter.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? _controller;
  List<CameraDescription>? cameras;

  List<DetectedObject> detectedObjects = [];
  Size cameraSize = Size(1, 1);

  bool _isDetecting = false;
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  String textStatus = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras == null || cameras!.isEmpty) {
      setState(() {
        textStatus = 'ไม่พบกล้อง';
      });
      return;
    }

    _controller = CameraController(
      cameras![0],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      setState(() {
        textStatus = 'ไม่สามารถเปิดกล้องได้: $e';
      });
      return;
    }

    if (!mounted) return;

    _controller!.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _detectObjects(image).then((_) => _isDetecting = false);
      }
    });

    setState(() {});
  }

  Future<void> _detectObjects(CameraImage image) async {
    try {
      final InputImageRotation rotation =
          InputImageRotationValue.fromRawValue(
            _controller!.description.sensorOrientation,
          )!;

      Uint8List convertYUV420ToUint8List(CameraImage image) {
        List<int> allBytes = [];
        for (var plane in image.planes) {
          allBytes.addAll(plane.bytes);
        }
        return Uint8List.fromList(allBytes);
      }

      // final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final Uint8List imageBytes = convertYUV420ToUint8List(image);
      final InputImage inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<DetectedObject> objects = await _objectDetector.processImage(
        inputImage,
      );

    //   for (var obj in objects) {
    //   print("🔍 วัตถุที่ตรวจจับ: ${obj.boundingBox}");
    // }

      setState(() {
        if (objects.isNotEmpty) {
          detectedObjects = objects;
          textStatus =
              "พบวัตถุ: ${objects.map((e) => e.labels.map((e) => "${e.text} (${e.confidence.toStringAsFixed(2)})").join(", ")).join(", ")}";
        } else {
          textStatus = "ไม่พบวัตถุ";
        }
      });
    } catch (e) {
      setState(() {
        textStatus = "เกิดข้อผิดพลาดในการตรวจจับวัตถุ : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    // return Scaffold(
    //   appBar: AppBar(title: Text('กล้อง')),
    //   body: Column(
    //     children: [
    //       SizedBox(
    //         // height: MediaQuery.of(context).size.height * 0.6,
    //         child: CameraPreview(_controller!),
    //       ),
    //       Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Text(
    //           textStatus,
    //           style: TextStyle(fontSize: 10, color: Colors.black),
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    return Scaffold(
      appBar: AppBar(title: Text('กล้อง')),
      body: Stack(
        children: [
          CameraPreview(_controller!), // กล้อง
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CustomPaint(
                painter: DetectionPainter(detectedObjects, cameraSize),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(
              textStatus,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
