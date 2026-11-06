import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/ads/ad_service.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/models/scan_record.dart';
import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';
import '../../core/utils/qr_image_exporter.dart';
import '../../core/utils/qr_payloads.dart';
import 'barcode_generator_panel.dart';

enum GenType { text, url, wifi, contact, phone, email, sms, location }

extension GenTypeX on GenType {
  /// English label - translate with `context.tr(type.label)` when displaying.
  String get label => switch (this) {
        GenType.text => 'Text',
        GenType.url => 'Website',
        GenType.wifi => 'Wi-Fi',
        GenType.contact => 'Contact',
        GenType.phone => 'Phone',
        GenType.email => 'Email',
        GenType.sms => 'SMS',
        GenType.location => 'Location',
      };

  IconData get icon => switch (this) {
        GenType.text => Icons.text_fields,
        GenType.url => Icons.link,
        GenType.wifi => Icons.wifi,
        GenType.contact => Icons.contact_page,
        GenType.phone => Icons.phone,
        GenType.email => Icons.email,
        GenType.sms => Icons.sms,
        GenType.location => Icons.location_on,
      };
}

/// Creates QR codes and barcodes locally (nothing is uploaded anywhere).
class GeneratorScreen extends StatefulWidget {
  final GenType initialType;

  /// Open directly on the "Barcode" tab (Code 128 / EAN).
  final bool initialBarcode;

  const GeneratorScreen({
    super.key,
    this.initialType = GenType.text,
    this.initialBarcode = false,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  static const List<Color> _qrColors = [
    Colors.black,
    Color(0xFF1E4FD8),
    Color(0xFF1B7F3B),
    Color(0xFFB3261E),
    Color(0xFF6A1B9A),
    Color(0xFF004D40),
  ];

  final _formKey = GlobalKey<FormState>();
  final _qrKey = GlobalKey();

  late GenType _type;
  late bool _barcodeMode;
  String? _payload;
  String? _lastSaved;
  Color _qrColor = Colors.black;

  final _text = TextEditingController();
  final _url = TextEditingController();
  final _ssid = TextEditingController();
  final _wifiPass = TextEditingController();
  final _name = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  final _org = TextEditingController();
  final _phone = TextEditingController();
  final _emailTo = TextEditingController();
  final _emailSubject = TextEditingController();
  final _emailBody = TextEditingController();
  final _smsNumber = TextEditingController();
  final _smsMessage = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  String _security = 'WPA';
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _barcodeMode = widget.initialBarcode;
  }

  @override
  void dispose() {
    for (final c in [
      _text, _url, _ssid, _wifiPass, _name, _contactPhone, _contactEmail,
      _org, _phone, _emailTo, _emailSubject, _emailBody, _smsNumber,
      _smsMessage, _lat, _lng,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('Required') : null;

  String? _emailValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return context.tr('Required');
    if (!t.contains('@') || !t.contains('.')) return context.tr('Invalid email');
    return null;
  }

  String? _rangeValidator(String? v, double limit) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null || d < -limit || d > limit) {
      return context
          .tr('Number between -{n} and {n}')
          .replaceAll('{n}', '${limit.toInt()}');
    }
    return null;
  }

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
            email: _contactEmail.text,
            organization: _org.text,
          ),
        GenType.email => QrPayloads.email(
            address: _emailTo.text,
            subject: _emailSubject.text,
            body: _emailBody.text,
          ),
        GenType.sms => QrPayloads.sms(
            number: _smsNumber.text,
            message: _smsMessage.text,
          ),
        GenType.location => QrPayloads.geo(lat: _lat.text, lng: _lng.text),
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

  /// Text field. [label] is an English key and is translated here.
  /// [ltr] keeps numbers / emails / links left-to-right in Arabic mode.
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
    TextInputType? keyboard,
    int maxLines = 1,
    bool obscure = false,
    bool ltr = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        obscureText: obscure,
        textDirection: ltr ? TextDirection.ltr : null,
        validator: validator ?? (required ? _required : null),
        decoration: InputDecoration(
          labelText: context.tr(label),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _formFields() {
    const decimal = TextInputType.numberWithOptions(signed: true, decimal: true);
    switch (_type) {
      case GenType.text:
        return _field(_text, 'Text', maxLines: 4);
      case GenType.url:
        return _field(_url, 'Website address (e.g. example.com)',
            keyboard: TextInputType.url, ltr: true);
      case GenType.phone:
        return _field(_phone, 'Phone number',
            keyboard: TextInputType.phone, ltr: true);
      case GenType.wifi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_ssid, 'Network name (SSID)'),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'WPA', label: Text('WPA/WPA2')),
                const ButtonSegment(value: 'WEP', label: Text('WEP')),
                ButtonSegment(value: 'nopass', label: Text(context.tr('None'))),
              ],
              selected: {_security},
              onSelectionChanged: (s) => setState(() => _security = s.first),
            ),
            const SizedBox(height: 12),
            if (_security != 'nopass') _field(_wifiPass, 'Password'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Hidden network')),
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
                required: false, keyboard: TextInputType.phone, ltr: true),
            _field(_contactEmail, 'Email',
                required: false,
                keyboard: TextInputType.emailAddress,
                ltr: true),
            _field(_org, 'Organization', required: false),
          ],
        );
      case GenType.email:
        return Column(
          children: [
            _field(_emailTo, 'Email address',
                keyboard: TextInputType.emailAddress,
                ltr: true,
                validator: _emailValidator),
            _field(_emailSubject, 'Subject', required: false),
            _field(_emailBody, 'Message', required: false, maxLines: 3),
          ],
        );
      case GenType.sms:
        return Column(
          children: [
            _field(_smsNumber, 'Phone number',
                keyboard: TextInputType.phone, ltr: true),
            _field(_smsMessage, 'Message', required: false, maxLines: 3),
          ],
        );
      case GenType.location:
        return Column(
          children: [
            _field(_lat, 'Latitude (e.g. 30.0444)',
                keyboard: decimal,
                ltr: true,
                validator: (v) => _rangeValidator(v, 90)),
            _field(_lng, 'Longitude (e.g. 31.2357)',
                keyboard: decimal,
                ltr: true,
                validator: (v) => _rangeValidator(v, 180)),
          ],
        );
    }
  }

  Widget _colorPicker() {
    return Row(
      children: [
        Text(context.tr('QR color')),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _qrColors)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _qrColor = c),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: c,
                    child: _qrColor == c
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Create code'))),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(context.tr('QR code')),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.view_week),
                  label: Text(context.tr('Barcode')),
                ),
              ],
              selected: {_barcodeMode},
              onSelectionChanged: (s) {
                FocusScope.of(context).unfocus();
                setState(() => _barcodeMode = s.first);
              },
            ),
            const SizedBox(height: 16),
            if (_barcodeMode)
              const BarcodeGeneratorPanel()
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in GenType.values)
                    ChoiceChip(
                      avatar: Icon(t.icon, size: 18),
                      label: Text(context.tr(t.label)),
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
              _colorPicker(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.qr_code_2),
                label: Text(context.tr('Generate')),
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
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: _qrColor,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: _qrColor,
                        ),
                        errorStateBuilder: (_, __) => SizedBox(
                          width: 240,
                          height: 240,
                          child: Center(
                              child: Text(context.tr('Content is too long'))),
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
                          final copied = context.tr('Copied');
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                              ClipboardData(text: _payload!));
                          messenger.showSnackBar(
                            SnackBar(content: Text(copied)),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(context.tr('Copy content')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => QrImageExporter.share(_qrKey),
                        icon: const Icon(Icons.ios_share),
                        label: Text(context.tr('Share image')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
