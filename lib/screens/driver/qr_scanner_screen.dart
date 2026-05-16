import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  /// Called when a valid QR code is detected.
  final void Function(String code) onDetected;

  const QrScannerScreen({super.key, required this.onDetected});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scanner;
  late final AnimationController _lineCtrl;
  late final Animation<double> _lineAnim;

  bool _detected = false;
  String? _lastCode;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Scanning line animation
    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _lineAnim =
        Tween(begin: 0.0, end: 1.0).animate(_lineCtrl);
  }

  @override
  void dispose() {
    _scanner.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _detected = true;
      _lastCode = code;
    });

    _scanner.stop();
    widget.onDetected(code);

    // Pop after short delay so user sees feedback
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan QR Resi',
          style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          // Torch toggle
          ValueListenableBuilder(
            valueListenable: _scanner,
            builder: (ctx, value, _) => IconButton(
              icon: Icon(
                value.torchState == TorchState.on
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: value.torchState == TorchState.on
                    ? Colors.amber
                    : Colors.white54,
              ),
              onPressed: _scanner.toggleTorch,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Feed ──────────────────────────────────
          MobileScanner(
            controller: _scanner,
            onDetect: _onDetect,
          ),

          // ── Overlay Dimmer ───────────────────────────────
          CustomPaint(
            painter: _ScannerOverlayPainter(
                detected: _detected),
            child: const SizedBox.expand(),
          ),

          // ── Scan Frame + Line ───────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._corners(),
                  // Scan line
                  if (!_detected)
                    AnimatedBuilder(
                      animation: _lineAnim,
                      builder: (_, __) => Positioned(
                        top: 10 +
                            (_lineAnim.value * 240),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF00E5FF),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                    Color(0x8800E5FF),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Success overlay
                  if (_detected)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676)
                            .withOpacity(0.25),
                        border: Border.all(
                          color: const Color(0xFF00E676),
                          width: 2,
                        ),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF00E676),
                          size: 64,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Bottom Hint ──────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_lastCode != null && _detected)
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676)
                          .withOpacity(0.15),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00E676)
                              .withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2,
                            color: Color(0xFF00E676),
                            size: 18),
                        const Gap(8),
                        Flexible(
                          child: Text(
                            _lastCode!,
                            style: GoogleFonts.firaCode(
                              color: const Color(0xFF00E676),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Arahkan kamera ke QR Code resi',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const size = 28.0;
    const thickness = 4.0;
    const color = Color(0xFF00E5FF);
    const r = Radius.circular(4);

    Widget corner(
            {required double? top,
            required double? left,
            required double? bottom,
            required double? right,
            required BorderRadius borderRadius}) =>
        Positioned(
          top: top,
          left: left,
          bottom: bottom,
          right: right,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border(
                top: (top != null && left != null) ||
                        (top != null && right != null)
                    ? const BorderSide(
                        color: color, width: thickness)
                    : BorderSide.none,
                left: (top != null && left != null) ||
                        (bottom != null && left != null)
                    ? const BorderSide(
                        color: color, width: thickness)
                    : BorderSide.none,
                bottom: (bottom != null && left != null) ||
                        (bottom != null && right != null)
                    ? const BorderSide(
                        color: color, width: thickness)
                    : BorderSide.none,
                right: (top != null && right != null) ||
                        (bottom != null && right != null)
                    ? const BorderSide(
                        color: color, width: thickness)
                    : BorderSide.none,
              ),
              borderRadius: borderRadius,
            ),
          ),
        );

    return [
      corner(
          top: 0,
          left: 0,
          bottom: null,
          right: null,
          borderRadius: const BorderRadius.only(topLeft: r)),
      corner(
          top: 0,
          left: null,
          bottom: null,
          right: 0,
          borderRadius:
              const BorderRadius.only(topRight: r)),
      corner(
          top: null,
          left: 0,
          bottom: 0,
          right: null,
          borderRadius:
              const BorderRadius.only(bottomLeft: r)),
      corner(
          top: null,
          left: null,
          bottom: 0,
          right: 0,
          borderRadius:
              const BorderRadius.only(bottomRight: r)),
    ];
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final bool detected;
  _ScannerOverlayPainter({required this.detected});

  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2;

    final paint = Paint()
      ..color = Colors.black.withOpacity(detected ? 0.3 : 0.65);

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
        const Radius.circular(8),
      ));

    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutoutPath),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.detected != detected;
}