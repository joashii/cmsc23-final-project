import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null) return;

    try {
      final data = jsonDecode(rawValue);

      if (data["type"] == "handoff") {
        setState(() => hasScanned = true);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: Text('Received Item Id: ${data["itemId"]}'),
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