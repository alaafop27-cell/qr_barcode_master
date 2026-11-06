import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';
import '../../core/utils/code_parser.dart';
import '../../core/widgets/app_logo.dart';
import '../generator/generator_screen.dart';
import '../result/result_screen.dart';

/// Dashboard: shows everything the app can do and jumps straight into it.
class HomeScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onScanImage;
  final ValueChanged<GenType> onCreate;
  final VoidCallback onCreateBarcode;
  final VoidCallback onOpenHistory;

  const HomeScreen({
    super.key,
    required this.onScan,
    required this.onScanImage,
    required this.onCreate,
    required this.onCreateBarcode,
    required this.onOpenHistory,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final recent = context.watch<HistoryRepository>().items.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _hero(context),
            const SizedBox(height: 24),

            _title(context, context.tr('Create a code')),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                for (final t in GenType.values)
                  _ServiceTile(
                    icon: t.icon,
                    label: context.tr(t.label),
                    onTap: () => onCreate(t),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.view_week, color: cs.primary),
                title: Text(context.tr('Create a barcode')),
                subtitle: const Text('Code 128, EAN-13, EAN-8'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onCreateBarcode,
              ),
            ),
            const SizedBox(height: 24),

            _title(context, context.tr('Reads everything')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in CodeType.values)
                  Chip(
                    avatar: Icon(t.icon, size: 16),
                    label: Text(context.tr(t.label)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _Perk(
                      icon: Icons.wifi_off, label: context.tr('Works offline')),
                ),
                Expanded(
                  child: _Perk(
                      icon: Icons.lock_outline, label: context.tr('Private')),
                ),
                Expanded(
                  child: _Perk(
                      icon: Icons.bolt, label: context.tr('Instant scan')),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _title(context, context.tr('Recent'))),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: onOpenHistory,
                    child: Text(context.tr('See all')),
                  ),
              ],
            ),
            if (recent.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr('Your scanned and created codes will appear here.'),
                    style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (final r in recent) _recentTile(context, r),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _hero(BuildContext context) {
    final seed = context.watch<SettingsController>().seedColor;
    final c1 = Color.lerp(seed, Colors.black, 0.3)!;
    final c2 = Color.lerp(seed, Colors.black, 0.65)!;
    final btnText = Color.lerp(seed, Colors.black, 0.5)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('QR & Barcode Master'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('Scan, create and manage codes'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: btnText,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(context.tr('Scan now')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScanImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(context.tr('From image')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentTile(BuildContext context, ScanRecord r) {
    final parsed =
        CodeParser.parse(r.rawValue, format: r.format, tr: context.tr);
    final cs = Theme.of(context).colorScheme;
    final kind = context.tr(
        r.source == ScanSource.generated ? 'Created' : 'Scanned');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Icon(parsed.type.icon, color: cs.onPrimaryContainer),
      ),
      title: Text(parsed.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${context.tr(parsed.type.label)}  •  $kind  •  '
        '${context.strings.shortDateTime(r.createdAt)}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResultScreen(record: r)),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cs.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Perk({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
