import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/ads/ad_service.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';
import '../../core/utils/qr_image_exporter.dart';
import '../../core/utils/qr_payloads.dart';

enum GenType { text, url, wifi, contact, phone }

extension on GenType {
  String get label => switch (this) {
        GenType.text => 'Text',
        GenType.url => 'URL',
        GenType.wifi => 'Wi-Fi',
        GenType.contact => 'Contact',
        GenType.phone => 'Phone',
      };

  IconData get icon => switch (this) {
        GenType.text => Icons.text_fields,
        GenType.url => Icons.link,
        GenType.wifi => Icons.wifi,
        GenType.contact => Icons.contact_page,
        GenType.phone => Icons.phone,
      };
}

/// Creates QR codes locally (nothing is uploaded anywhere).
class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qrKey = GlobalKey();

  GenType _type = GenType.text;
  String? _payload;
  String? _lastSaved;

  final _text = TextEditingController();
  final _url = TextEditingController();
  final _ssid = TextEditingController();
  final _wifiPass = TextEditingController();
  final _name = TextEditingController();
  final _contactPhone = TextEditingController();
  final _email = TextEditingController();
  final _org = TextEditingController();
  final _phone = TextEditingController();

  String _security = 'WPA';
  bool _hidden = false;

  @override
  void dispose() {
    for (final c in [
      _text, _url, _ssid, _wifiPass, _name, _contactPhone, _email, _org, _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String _buildPayload() => switch (_type) {
        GenType.text => QrPayloads.text(_text.text),
        GenType.url => QrPayloads.url(_url.text),
        GenType.phone => QrPayloads.phone(_phone.text),
        GenType.wifi => QrPayloads.wifi(
            ssid: _ssid.text.trim(),
            password: _wifiPass.text,
            security: _security,
            hidden: _hidden,
          ),
        GenType.contact => QrPayloads.vCard(
            name: _name.text,
            phone: _contactPhone.text,
            email: _email.text,
            organization: _org.text,
          ),
      };

  Future<void> _generate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    setState(() => _payload = payload);

    final settings = context.read<SettingsController>();
    final history = context.read<HistoryRepository>();
    if (settings.saveHistory && payload != _lastSaved) {
      _lastSaved = payload;
      await history.add(ScanRecord.create(
        rawValue: payload,
        format: 'qrCode',
        source: ScanSource.generated,
      ));
    }
    AdService.instance.registerActionAndMaybeShow();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        obscureText: obscure,
        validator: required ? _required : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _formFields() {
    switch (_type) {
      case GenType.text:
        return _field(_text, 'Text', maxLines: 4);
      case GenType.url:
        return _field(_url, 'Website address (e.g. example.com)',
            keyboard: TextInputType.url);
      case GenType.phone:
        return _field(_phone, 'Phone number', keyboard: TextInputType.phone);
      case GenType.wifi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_ssid, 'Network name (SSID)'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'WPA', label: Text('WPA/WPA2')),
                ButtonSegment(value: 'WEP', label: Text('WEP')),
                ButtonSegment(value: 'nopass', label: Text('None')),
              ],
              selected: {_security},
              onSelectionChanged: (s) => setState(() => _security = s.first),
            ),
            const SizedBox(height: 12),
            if (_security != 'nopass')
              _field(_wifiPass, 'Password', obscure: false),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hidden network'),
              value: _hidden,
              onChanged: (v) => setState(() => _hidden = v),
            ),
          ],
        );
      case GenType.contact:
        return Column(
          children: [
            _field(_name, 'Full name'),
            _field(_contactPhone, 'Phone',
                required: false, keyboard: TextInputType.phone),
            _field(_email, 'Email',
                required: false, keyboard: TextInputType.emailAddress),
            _field(_org, 'Organization', required: false),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create QR code')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in GenType.values)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      _type = t;
                      _payload = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Form(key: _formKey, child: _formFields()),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generate'),
            ),
            if (_payload != null) ...[
              const SizedBox(height: 24),
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: _payload!,
                      size: 240,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                      errorStateBuilder: (_, __) => const SizedBox(
                        width: 240,
                        height: 240,
                        child: Center(child: Text('Content is too long')),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _payload!));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy content'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => QrImageExporter.share(_qrKey),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share image'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
