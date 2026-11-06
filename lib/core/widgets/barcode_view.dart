import 'package:flutter/material.dart';

import '../utils/barcode_encoder.dart';

/// Draws a 1D barcode (bars + human readable text) on a white background
/// area supplied by the caller. Size is fixed so it can be captured as an image.
class BarcodeView extends StatelessWidget {
  final EncodedBarcode code;
  final double width;
  final double height;
  final Color color;

  const BarcodeView({
    super.key,
    required this.code,
    this.width = 280,
    this.height = 130,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarcodePainter(code, color),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final EncodedBarcode code;
  final Color color;

  _BarcodePainter(this.code, this.color);

  /// Empty margin (in modules) left and right of the bars.
  static const double _quiet = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = code.modules;
    final total = modules.length + 2 * _quiet;
    final mw = size.width / total; // width of one module in pixels

    final double fontSize = (mw * 8).clamp(10.0, 20.0).toDouble();
    final textHeight = fontSize * 1.35;
    final barHeight = size.height - textHeight;

    // Bars (runs of consecutive "true" modules are merged into one rect).
    final paint = Paint()..color = color;
    var i = 0;
    while (i < modules.length) {
      if (!modules[i]) {
        i++;
        continue;
      }
      var j = i;
      while (j < modules.length && modules[j]) {
        j++;
      }
      canvas.drawRect(
        Rect.fromLTWH((_quiet + i) * mw, 0, (j - i) * mw, barHeight),
        paint,
      );
      i = j;
    }

    // Human readable text.
    void text(String s, double centerX) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(color: color, fontSize: fontSize, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, barHeight + textHeight * 0.12));
    }

    final d = code.data;
    switch (code.kind) {
      case BarcodeKind.code128:
        text(d, size.width / 2);
      case BarcodeKind.ean13:
        text(d[0], (_quiet - 5) * mw);
        for (var k = 1; k <= 6; k++) {
          text(d[k], (_quiet + 3 + (k - 1) * 7 + 3.5) * mw);
        }
        for (var k = 7; k <= 12; k++) {
          text(d[k], (_quiet + 50 + (k - 7) * 7 + 3.5) * mw);
        }
      case BarcodeKind.ean8:
        for (var k = 0; k < 4; k++) {
          text(d[k], (_quiet + 3 + k * 7 + 3.5) * mw);
        }
        for (var k = 4; k < 8; k++) {
          text(d[k], (_quiet + 36 + (k - 4) * 7 + 3.5) * mw);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) =>
      old.code != code || old.color != color;
}
