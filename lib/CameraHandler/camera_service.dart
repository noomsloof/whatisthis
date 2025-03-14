import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;
  List<CameraDescription>? cameras;

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras == null || cameras!.isEmpty) {
      throw "ไม่พบกล้อง";
    }

    controller = CameraController(
      cameras![0],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
  }

  void dispose() {
    controller?.stopImageStream();
    controller?.dispose();
  }
}
