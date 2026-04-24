import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final Future<void> Function(String) onScanned;

  const QRScannerScreen({super.key, required this.onScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _handled = false;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _handled = true;
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    _controller.toggleTorch();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled || _isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() {
          _handled = true;
          _isProcessing = true;
        });

        // Add a small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          await widget.onScanned(code);
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('QR Scanner'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [
                  const Color(0xFF0F3460),
                  const Color(0xFF1A1A2E),
                ]
                    : [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          // QR Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Camera Error',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check camera permissions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _controller.start();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Scanner Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Processing QR Code...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Instructions
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.only(
                  bottom: isSmallScreen ? 16 : 24,
                  left: 20,
                  right: 20,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: const Color(0xFF667EEA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scan Member QR Code',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Align the QR code within the frame to scan automatically',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInstructionItem(
                          icon: Icons.center_focus_strong_rounded,
                          text: 'Center QR',
                          isDarkMode: false,
                        ),
                        _buildInstructionItem(
                          icon: Icons.light_mode_rounded,
                          text: 'Good Lighting',
                          isDarkMode: false,
                        ),
                        _buildInstructionItem(
                          icon: Icons.stay_primary_portrait_rounded,
                          text: 'Steady Hands',
                          isDarkMode: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scanner Frame Animation
          if (!_isProcessing)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _buildCornerDecoration(
                          Alignment.topLeft, Colors.white),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCornerDecoration(
                          Alignment.topRight, Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCornerDecoration(
                          Alignment.bottomLeft, Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCornerDecoration(
                          Alignment.bottomRight, Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF667EEA),
            size: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCornerDecoration(Alignment alignment, Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: alignment == Alignment.topLeft
              ? Radius.zero
              : const Radius.circular(20),
          topRight: alignment == Alignment.topRight
              ? Radius.zero
              : const Radius.circular(20),
          bottomLeft: alignment == Alignment.bottomLeft
              ? Radius.zero
              : const Radius.circular(20),
          bottomRight: alignment == Alignment.bottomRight
              ? Radius.zero
              : const Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: color,
            width: 4,
          ),
          left: BorderSide(
            color: color,
            width: alignment == Alignment.topLeft ||
                alignment == Alignment.bottomLeft
                ? 4
                : 0,
          ),
          right: BorderSide(
            color: color,
            width: alignment == Alignment.topRight ||
                alignment == Alignment.bottomRight
                ? 4
                : 0,
          ),
          bottom: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Calculate frame dimensions
    final frameWidth = size.width * 0.8;
    final frameHeight = size.width * 0.8;
    final frameLeft = (size.width - frameWidth) / 2;
    final frameTop = size.height * 0.3;
    final frameRight = frameLeft + frameWidth;
    final frameBottom = frameTop + frameHeight;

    // Draw outer darkened area
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, frameTop), paint);
    canvas.drawRect(
        Rect.fromLTRB(0, frameTop, frameLeft, frameBottom), paint);
    canvas.drawRect(Rect.fromLTRB(frameRight, frameTop, size.width, frameBottom),
        paint);
    canvas.drawRect(Rect.fromLTRB(0, frameBottom, size.width, size.height), paint);

    // Draw frame border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight),
        const Radius.circular(20),
      ),
      borderPaint,
    );

    // Draw scanning animation line
    final linePaint = Paint()
      ..color = const Color(0xFF667EEA)
      ..style = PaintingStyle.fill;

    final animationValue =
        (DateTime.now().millisecondsSinceEpoch % 2000) / 2000;
    final lineY = frameTop + frameHeight * animationValue;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft + 10, lineY - 2, frameWidth - 20, 4),
        const Radius.circular(2),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}