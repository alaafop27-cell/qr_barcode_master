import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_service.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/feedback_service.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';
import '../result/result_screen.dart';

/// Real-time scanner for QR codes and all common barcode formats.
class ScannerScreen extends StatefulWidget {
  /// When true, the gallery picker opens right away (used by "From image").
  final bool autoPickImage;
  const ScannerScreen({super.key, this.autoPickImage = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _busy = false;
  double _zoom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoPickImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickFromGallery();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _line.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_busy) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _safe(_controller.start);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _safe(_controller.stop);
    }
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {
      // start/stop can throw if already in that state - safe to ignore.
    }
  }

  String? _firstValue(BarcodeCapture? capture, {required void Function(Barcode) onHit}) {
    if (capture == null) return null;
    for (final b in capture.barcodes) {
      if ((b.rawValue ?? '').isNotEmpty) {
        onHit(b);
        return b.rawValue;
      }
    }
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    Barcode? hit;
    _firstValue(capture, onHit: (b) => hit = b);
    if (hit == null) return;
    await _handleResult(hit!.rawValue!, hit!.format.name);
  }

  Future<void> _pickFromGallery() async {
    final messenger = ScaffoldMessenger.of(context);
    final notFound = context.tr('No QR code or barcode found in that image');
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    BarcodeCapture? capture;
    try {
      capture = await _controller.analyzeImage(picked.path);
    } catch (_) {}
    Barcode? hit;
    _firstValue(capture, onHit: (b) => hit = b);
    if (hit == null) {
      messenger.showSnackBar(SnackBar(content: Text(notFound)));
      return;
    }
    if (_busy) return;
    await _handleResult(hit!.rawValue!, hit!.format.name);
  }

  Future<void> _handleResult(String raw, String format) async {
    _busy = true;
    final settings = context.read<SettingsController>();
    final history = context.read<HistoryRepository>();

    await FeedbackService.scanFeedback(
      sound: settings.sound,
      vibrate: settings.vibration,
    );

    final record = ScanRecord.create(
      rawValue: raw,
      format: format,
      source: ScanSource.scanned,
    );
    if (settings.saveHistory) await history.add(record);

    await _safe(_controller.stop);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
    );

    AdService.instance.registerActionAndMaybeShow();
    if (!mounted) return;
    await _safe(_controller.start);
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _CameraError(error: error),
          ),
          // Dimmed surround, corner brackets and animated red scan line.
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanOverlayPainter(
                animation: _line,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                const Spacer(),
                _zoomBar(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            context.tr('Scan'),
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final on = state.torchState == TorchState.on;
              return IconButton(
                tooltip: context.tr('Flashlight'),
                color: Colors.white,
                icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                onPressed: state.torchState == TorchState.unavailable
                    ? null
                    : () => _safe(_controller.toggleTorch),
              );
            },
          ),
          IconButton(
            tooltip: context.tr('Scan from image'),
            color: Colors.white,
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _pickFromGallery,
          ),
          IconButton(
            tooltip: context.tr('Switch camera'),
            color: Colors.white,
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _safe(_controller.switchCamera),
          ),
        ],
      ),
    );
  }

  Widget _zoomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.zoom_out, color: Colors.white),
          Expanded(
            child: Slider(
              value: _zoom,
              onChanged: (v) {
                setState(() => _zoom = v);
                _safe(() => _controller.setZoomScale(v));
              },
            ),
          ),
          const Icon(Icons.zoom_in, color: Colors.white),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography, color: Colors.white70, size: 64),
          const SizedBox(height: 16),
          Text(
            context.tr(denied
                ? 'Camera permission is required to scan. Enable it in the phone Settings under Apps > Permissions.'
                : 'The camera is not available.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Dark surround + corner brackets + moving red line (like classic scanners).
class _ScanOverlayPainter extends CustomPainter {
  final Animation<double> animation;
  final Color accent;

  _ScanOverlayPainter({required this.animation, required this.accent})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.7;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: side,
      height: side,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Dimmed area with transparent hole.
    final overlay = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(overlay, Paint()..color = Colors.black.withAlpha(120));

    // Corner brackets.
    final corner = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 32.0;
    for (final c in [
      [rect.topLeft, 1.0, 1.0],
      [rect.topRight, -1.0, 1.0],
      [rect.bottomLeft, 1.0, -1.0],
      [rect.bottomRight, -1.0, -1.0],
    ]) {
      final p = c[0] as Offset;
      final dx = c[1] as double;
      final dy = c[2] as double;
      canvas.drawLine(p, p + Offset(len * dx, 0), corner);
      canvas.drawLine(p, p + Offset(0, len * dy), corner);
    }

    // Moving red line.
    final y = rect.top + 12 + (rect.height - 24) * animation.value;
    canvas.drawLine(
      Offset(rect.left + 8, y),
      Offset(rect.right - 8, y),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) => old.accent != accent;
}
