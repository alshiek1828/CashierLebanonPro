import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_strings.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isScanning = true;
  String? _scannedBarcode;
  String? _manualBarcode;
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanTitle),
        actions: [
          // Flash Toggle
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          // Camera Switch
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner View (takes available space)
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onBarcodeDetected,
                ),
                
                // Scan Overlay
                CustomPaint(
                  painter: _ScannerOverlayPainter(),
                  size: Size.infinite,
                ),
                
                // Scanning Indicator
                if (_isScanning)
                  Positioned(
                    bottom: 100,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(AppStrings.scanningActive, style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                
                // Result Display
                if (_scannedBarcode != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(AppStrings.scanSuccess, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(_scannedBarcode!, style: const TextStyle(color: Colors.white, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Bottom Controls
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.manualEntry,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Manual Entry Field
                  TextField(
                    controller: _manualController,
                    decoration: InputDecoration(
                      labelText: AppStrings.enterBarcode,
                      prefixIcon: const Icon(Icons.keyboard),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _submitManualBarcode(),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    onSubmitted: (_) => _submitManualBarcode(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action Buttons
                  if (_scannedBarcode != null || _manualBarcode != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _returnResult,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('تأكيد واستخدام'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text(AppStrings.closeScanner),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _scannedBarcode = barcode.rawValue!;
          _isScanning = false;
        });
        
        // Vibrate or play sound (optional)
        
        break; // Stop after first valid barcode
      }
    }
  }

  void _submitManualBarcode() {
    final text = _manualController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _manualBarcode = text;
        _scannedBarcode = text;
      });
    }
  }

  void _returnResult() {
    final result = _scannedBarcode ?? _manualBarcode;
    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }
}

// ==================== SCANNER OVERLAY PAINTER ====================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.fill;
    
    final clearPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw dark overlay with transparent center
    canvas.saveLayer(const Rect.largest, paint);
    
    // Draw full overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Clear center area for scanner
    final scanAreaWidth = size.width * 0.7;
    final scanAreaHeight = size.height * 0.5;
    final scanAreaLeft = (size.width - scanAreaWidth) / 2;
    final scanAreaTop = (size.height - scanAreaHeight) / 2;
    
    canvas.drawRect(
      Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
      clearPaint,
    );
    
    canvas.restore();
    
    // Draw border around scan area
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
      const Radius.circular(16),
    );
    canvas.drawRRect(borderRect, borderPaint);
    
    // Draw corner accents
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanAreaTop + 30),
      Offset(scanAreaLeft + 10, scanAreaTop + 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanAreaTop + 10),
      Offset(scanAreaLeft + 30, scanAreaTop + 10),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - 30, scanAreaTop + 10),
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + 10),
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + 30),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanAreaTop + scanAreaHeight - 30),
      Offset(scanAreaLeft + 10, scanAreaTop + scanAreaHeight - 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanAreaTop + scanAreaHeight - 10),
      Offset(scanAreaLeft + 30, scanAreaTop + scanAreaHeight - 10),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - 30, scanAreaTop + scanAreaHeight - 10),
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + scanAreaHeight - 10),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + scanAreaHeight - 10),
      Offset(scanAreaLeft + scanAreaWidth - 10, scanAreaTop + scanAreaHeight - 30),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
