import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGenerateScreen extends StatelessWidget {
  final String itemId;

  const QRGenerateScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      "itemId": itemId,
      "type": "handoff"
    });

    return Scaffold(
      appBar: AppBar(title: const Text("QR Handshake")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Let the receiver scan this QR",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            QrImageView(
              data: qrData,
              size: 250,
              version: QrVersions.auto,
            ),

            const SizedBox(height: 20),
            Text("Item ID: $itemId"),
          ],
        ),
      ),
    );
  }
}