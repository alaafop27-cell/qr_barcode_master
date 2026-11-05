import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ads/banner_ad_widget.dart';
import '../../core/models/scan_record.dart';
import '../../core/utils/code_parser.dart';

/// Shows the decoded content of a scanned / generated code and the
/// relevant actions (open link, call, copy Wi-Fi password, ...).
class ResultScreen extends StatelessWidget {
  final ScanRecord record;
  const ResultScreen({super.key, required this.record});

  Future<void> _run(BuildContext context, CodeAction action) async {
    final messenger = ScaffoldMessenger.of(context);
    if (action.copyText != null) {
      await Clipboard.setData(ClipboardData(text: action.copyText!));
      messenger.showSnackBar(const SnackBar(content: Text('Copied')));
      return;
    }
    final uri = action.uri;
    if (uri == null) return;
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No app found to open this')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = CodeParser.parse(record.rawValue, format: record.format);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(parsed.type.label)),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: cs.primary,
                    child: Icon(parsed.type.icon, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parsed.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${prettyFormat(record.format)}  •  '
                          '${DateFormat.yMMMd().add_Hm().format(record.createdAt)}',
                          style: text.bodySmall
                              ?.copyWith(color: cs.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Parsed fields
          if (parsed.fields.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in parsed.fields.entries) ...[
                      Text(e.key,
                          style: text.labelMedium?.copyWith(color: cs.primary)),
                      SelectableText(e.value, style: text.bodyLarge),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          if (parsed.fields.isNotEmpty) const SizedBox(height: 12),

          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in parsed.actions)
                FilledButton.tonalIcon(
                  onPressed: () => _run(context, a),
                  icon: Icon(a.icon),
                  label: Text(a.label),
                ),
              FilledButton.tonalIcon(
                onPressed: () => Share.share(record.rawValue),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              if (parsed.actions.every((a) => a.copyText == null))
                FilledButton.tonalIcon(
                  onPressed: () => _run(
                    context,
                    CodeAction('Copy', Icons.copy, copyText: record.rawValue),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Raw content
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raw content',
                      style: text.labelMedium?.copyWith(color: cs.primary)),
                  const SizedBox(height: 4),
                  SelectableText(record.rawValue),
                ],
              ),
            ),
          ),

          // QR preview (skipped for very long payloads)
          if (record.rawValue.length <= 1000) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: record.rawValue,
                  size: 180,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (_, __) => const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: Text('Cannot render QR')),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
