import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures a widget wrapped in a [RepaintBoundary] (identified by [key]) as a
/// PNG and opens the system share sheet (the user can save it to Gallery,
/// send it, print it, ...).
class QrImageExporter {
  QrImageExporter._();

  static Future<void> share(GlobalKey key, {String? text}) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(data.buffer.asUint8List());

    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
