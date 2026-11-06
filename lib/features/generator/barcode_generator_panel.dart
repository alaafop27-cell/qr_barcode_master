import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_service.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';
import '../../core/utils/barcode_encoder.dart';
import '../../core/utils/qr_image_exporter.dart';
import '../../core/widgets/barcode_view.dart';

/// "Barcode" tab of the generator: Code 128, EAN-13 and EAN-8.
/// Everything is drawn locally; nothing is uploaded.
class BarcodeGeneratorPanel extends StatefulWidget {
  const BarcodeGeneratorPanel({super.key});

  @override
  State<BarcodeGeneratorPanel> createState() => _BarcodeGeneratorPanelState();
}

class _BarcodeGeneratorPanelState extends State<BarcodeGeneratorPanel> {
  final _formKey = GlobalKey<FormState>();
  final _imageKey = GlobalKey();
  final _input = TextEditingController();

  BarcodeKind _kind = BarcodeKind.code128;
  EncodedBarcode? _result;
  String? _lastSaved;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final code = BarcodeEncoder.encode(_kind, _input.text);
    setState(() => _result = code);

    final settings = context.read<SettingsController>();
    final history = context.read<HistoryRepository>();
    final key = '${_kind.formatName}:${code.data}';
    if (settings.saveHistory && key != _lastSaved) {
      _lastSaved = key;
      await history.add(ScanRecord.create(
        rawValue: code.data,
        format: _kind.formatName,
        source: ScanSource.generated,
      ));
    }
    AdService.instance.registerActionAndMaybeShow();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in BarcodeKind.values)
              ChoiceChip(
                label: Text(k.label),
                selected: _kind == k,
                onSelected: (_) => setState(() {
                  _kind = k;
                  _result = null;
                  _input.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _input,
            textDirection: TextDirection.ltr,
            keyboardType:
                _kind.digitsOnly ? TextInputType.number : TextInputType.text,
            inputFormatters: [
              if (_kind.digitsOnly) FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_kind.maxLength),
            ],
            validator: (v) =>
                BarcodeEncoder.validate(_kind, v ?? '', tr: context.tr),
            decoration: InputDecoration(
              labelText: context.tr('Barcode content'),
              helperText: context.tr(_kind.hint),
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.view_week),
          label: Text(context.tr('Generate barcode')),
        ),
        if (result != null) ...[
          const SizedBox(height: 24),
          Center(
            child: RepaintBoundary(
              key: _imageKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: BarcodeView(code: result),
              ),
            ),
          ),
          if (result.kind != BarcodeKind.code128) ...[
            const SizedBox(height: 8),
            Text(
              '${context.tr('Number with check digit')}: ${result.data}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final copied = context.tr('Copied');
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: result.data));
                    messenger.showSnackBar(SnackBar(content: Text(copied)));
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(context.tr('Copy content')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => QrImageExporter.share(_imageKey),
                  icon: const Icon(Icons.ios_share),
                  label: Text(context.tr('Share image')),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
