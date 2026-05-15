import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState
    extends State<SelfieVerificationScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  XFile? selfie;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    controller = CameraController(
      cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      ),
      ResolutionPreset.medium,
    );

    await controller!.initialize();
    setState(() {});
  }

  Future<void> takeSelfie() async {
    if (controller == null || !controller!.value.isInitialized) return;

    final image = await controller!.takePicture();

    setState(() {
      selfie = image;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Verified"),
        content: const Text("Selfie Verification Successful 🎉"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Selfie Verification")),
      body: controller == null || !controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: CameraPreview(controller!),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Selfie"),
                    onPressed: takeSelfie,
                  ),
                ),
              ],
            ),
    );
  }
}