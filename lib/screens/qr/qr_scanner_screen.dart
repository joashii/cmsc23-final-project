import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final String claimId;

  const QRScannerScreen({super.key, required this.claimId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool hasScanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (hasScanned) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null) return;

    try {
      final data = jsonDecode(rawValue);

      if (data["type"] == "handover") {
        setState(() => hasScanned = true);

        final firestore = FirebaseFirestore.instance;

        final claimRef = firestore.collection("claims").doc(widget.claimId);
        final itemRef = firestore.collection("food_items").doc(data["itemId"]);

        // UPDATE CLAIM
        await claimRef.update({
          "status": "completed",
          "qrVerified": true,
          "completedAt": FieldValue.serverTimestamp(),
        });

        // UPDATE ITEM
        await itemRef.update({
          "status": "Completed",
          "claimedAt": Timestamp.now(),
          "claimedBy": claimRef.id,
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Handover Completed"),
            content: Text(
              'Item ${data["itemId"]} has been successfully claimed.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      // invalid QR
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR")),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}