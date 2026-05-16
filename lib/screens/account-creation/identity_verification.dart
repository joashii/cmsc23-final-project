import 'dart:io';
import 'package:camera/camera.dart';
import 'package:elbeats/provider/auth.provider.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:elbeats/screens/feed.dart';
import 'package:elbeats/components/selfie_verification.dart';
import 'package:provider/provider.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  File? _image;
  // final ImagePicker _picker = ImagePicker();

  // Future<void> _takePhoto() async {
  //   final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
  //   if (photo != null) setState(() => _image = File(photo.path));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Identity Verification")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                "Take a quick photo to verify your identity.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Preview Box
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // 1. Wait for the user to finish in the camera screen
                  final XFile? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelfieVerification(),
                    ),
                  );

                  // 2. If we got an image back, update the state
                  if (result != null) {
                    setState(() {
                      _image = File(result.path);
                    });
                  }
                },
                icon: const Icon(Icons.camera),
                label: const Text("Open Camera"),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _image == null
                    ? null
                    : () {
                        // Finish and go to Feed (where the Notification Modal will trigger)
                        Provider.of<UserAuthProvider>(
                          context,
                          listen: false,
                        ).setNewRegistration(true);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FoodFeedPage(),
                          ),
                          (route) => false, // Clears navigation stack
                        );
                      },
                child: const Text("Finalize Registration"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
