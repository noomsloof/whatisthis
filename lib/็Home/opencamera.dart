import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
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

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras == null || cameras!.isEmpty) {
      setState(() {
        textStatus = 'ไม่พบกล้อง';
      });
      return;
    }

    _controller = CameraController(cameras![0], ResolutionPreset.medium);

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
    final InputImageRotation rotation = InputImageRotationValue.fromRawValue(_controller!.description.sensorOrientation)!;
    
    final InputImage inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,  // ใช้ rotation ที่ได้จาก sensorOrientation
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);

    setState(() {
      if (objects.isNotEmpty) {
        textStatus = "พบวัตถุ: ${objects.map((e) => e.labels.map((e) => e.text).join(", ")).join(", ")}";
        print("พบวัตถุ");
      } else {
        textStatus = "ไม่พบวัตถุ";
        print("ไม่พบวัตถุ");
      }
    });
  } catch (e) {
    setState(() {
      textStatus = "เกิดข้อผิดพลาดในการตรวจจับวัตถุ: $e";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('กล้อง')),
      body: Column(
        children: [
          CameraPreview(_controller!),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              textStatus,
              style: TextStyle(fontSize: 20, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
