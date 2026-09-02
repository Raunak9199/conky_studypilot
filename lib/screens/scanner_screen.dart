import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        try {
          final data = json.decode(barcode.rawValue!);
          if (data['ip'] != null &&
              data['port'] != null &&
              data['token'] != null) {
            _hasScanned = true;
            _controller.stop();
            Navigator.of(context).pop(data);
            return;
          }
        } catch (e) {
          // Not a valid JSON or not our sync data
          log("Sync failed: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sync failed: Not a valid sync QR code"),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Desktop QR')),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
