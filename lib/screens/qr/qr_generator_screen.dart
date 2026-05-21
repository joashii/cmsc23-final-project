import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String claimId;
  final String itemId;

  const QRGeneratorScreen({
    super.key,
    required this.claimId,
    required this.itemId,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection("claims")
        .doc(widget.claimId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();

      if (data == null) return;

      // 🔥 AUTO CLOSE WHEN SCANNED
      if (data["qrVerified"] == true) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = jsonEncode({
      "claimId": widget.claimId,
      "itemId": widget.itemId,
      "type": "handover",
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Generate QR")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: data,
              size: 250,
            ),
            const SizedBox(height: 20),
            const Text("Waiting for scan..."),
          ],
        ),
      ),
    );
  }
}