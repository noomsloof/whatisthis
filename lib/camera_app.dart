import 'package:flutter/material.dart';
import 'CameraHandler/camera_service.dart';
import 'ObjectDetectionHandler/object_detection_service.dart';
import 'package:camera/camera.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraService _cameraService = CameraService();
  ObjectDetectionService _objectDetectionService = ObjectDetectionService();
  String textStatus = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initCamera();
      _cameraService.controller!.startImageStream((image) async {
        final status = await _objectDetectionService.detectObjects(image);
        if (mounted) {
          setState(() {
            textStatus = status;
          });
        }
      });
    } catch (e) {
      setState(() {
        textStatus = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _objectDetectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraService.controller == null || !_cameraService.controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('กล้อง')),
      body: Column(
        children: [
          SizedBox(
            child: CameraPreview(_cameraService.controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              textStatus,
              style: TextStyle(fontSize: 10, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
