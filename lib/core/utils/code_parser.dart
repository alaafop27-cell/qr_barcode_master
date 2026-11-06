import 'package:flutter/material.dart';

/// Kinds of content the app recognises inside a QR code / barcode.
enum CodeType {
  url,
  wifi,
  contact,
  email,
  phone,
  sms,
  geo,
  calendar,
  product,
  text,
}

extension CodeTypeX on CodeType {
  /// English label - translate with `context.tr(type.label)` when displaying.
  String get label => switch (this) {
        CodeType.url => 'Website',
        CodeType.wifi => 'Wi-Fi',
        CodeType.contact => 'Contact',
        CodeType.email => 'Email',
        CodeType.phone => 'Phone',
        CodeType.sms => 'SMS',
        CodeType.geo => 'Location',
        CodeType.calendar => 'Calendar event',
        CodeType.product => 'Product',
        CodeType.text => 'Text',
      };

  IconData get icon => switch (this) {
        CodeType.url => Icons.link,
        CodeType.wifi => Icons.wifi,
        CodeType.contact => Icons.contact_page,
        CodeType.email => Icons.email,
        CodeType.phone => Icons.phone,
        CodeType.sms => Icons.sms,
        CodeType.geo => Icons.location_on,
        CodeType.calendar => Icons.event,
        CodeType.product => Icons.shopping_bag,
        CodeType.text => Icons.text_fields,
      };
}

/// Human friendly barcode format name (English; translate when displaying).
String prettyFormat(String name) => const {
      'qrCode': 'QR Code',
      'ean13': 'EAN-13',
      'ean8': 'EAN-8',
      'upcA': 'UPC-A',
      'upcE': 'UPC-E',
      'code128': 'Code 128',
      'code39': 'Code 39',
      'code93': 'Code 93',
      'itf': 'ITF',
      'codabar': 'Codabar',
      'dataMatrix': 'Data Matrix',
      'pdf417': 'PDF417',
      'aztec': 'Aztec',
    }[name] ??
    name;

/// A button shown on the result screen: either opens a [uri] or copies
/// [copyText] to the clipboard.
class CodeAction {
  final String label;
  final IconData icon;
  final Uri? uri;
  final String? copyText;

  const CodeAction(this.label, this.icon, {this.uri, this.copyText});
}

class ParsedCode {
  final CodeType type;
  final String raw;

  /// Short summary used as list title.
  final String title;

  /// Ordered label -> value pairs shown on the result screen.
  final Map<String, String> fields;
  final List<CodeAction> actions;

  const ParsedCode({
    required this.type,
    required this.raw,
    required this.title,
    this.fields = const {},
    this.actions = const [],
  });
}

/// Turns raw scanned text into a typed, human readable [ParsedCode].
///
/// Pass `tr: context.tr` to get field names / button labels in the current
/// language. The scanned content itself is never translated.
class CodeParser {
  CodeParser._();

  static const Set<String> _productFormats = {'ean13', 'ean8', 'upcA', 'upcE'};
  static final RegExp _emailRe =
      RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');
  static final RegExp _phoneRe = RegExp(r'^\+?[0-9][0-9\s\-().]{5,19}$');
  static final RegExp _urlRe = RegExp(r'^https?://\S+$', caseSensitive: false);

  static String _identity(String s) => s;

  /// Translator for the parse currently running (parsing is synchronous).
  static String Function(String) _t = _identity;

  static ParsedCode parse(
    String raw, {
    String format = 'qrCode',
    String Function(String)? tr,
  }) {
    _t = tr ?? _identity;
    final v = raw.trim();
    final lower = v.toLowerCase();

    if (_productFormats.contains(format)) return _product(v, format);
    if (lower.startsWith('wifi:')) return _wifi(v);
    if (lower.startsWith('begin:vcard') || lower.startsWith('mecard:')) {
      return _contact(v);
    }
    if (lower.startsWith('begin:vevent') ||
        lower.startsWith('begin:vcalendar')) {
      return _calendar(v);
    }
    if (lower.startsWith('geo:')) return _geo(v);
    if (lower.startsWith('mailto:') ||
        lower.startsWith('matmsg:') ||
        _emailRe.hasMatch(v)) {
      return _email(v);
    }
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) return _sms(v);
    if (lower.startsWith('tel:') ||
        (format == 'qrCode' && _phoneRe.hasMatch(v))) {
      return _phone(v);
    }
    if (_urlRe.hasMatch(v) || lower.startsWith('www.')) return _url(v);
    return _text(v);
  }

  // ---------------------------------------------------------------- types

  static ParsedCode _url(String v) {
    final full = v.toLowerCase().startsWith('www.') ? 'https://$v' : v;
    final uri = Uri.tryParse(full);
    return ParsedCode(
      type: CodeType.url,
      raw: v,
      title: v,
      fields: {_t('URL'): v},
      actions: [
        if (uri != null)
          CodeAction(_t('Open'), Icons.open_in_browser, uri: uri),
        CodeAction(_t('Copy link'), Icons.copy, copyText: v),
      ],
    );
  }

  static ParsedCode _text(String v) => ParsedCode(
        type: CodeType.text,
        raw: v,
        title: v,
        actions: [
          CodeAction(_t('Search web'), Icons.search,
              uri: Uri.parse(
                  'https://www.google.com/search?q=${Uri.encodeQueryComponent(v)}')),
        ],
      );

  static ParsedCode _product(String v, String format) => ParsedCode(
        type: CodeType.product,
        raw: v,
        title: v,
        fields: {_t('Barcode'): v, _t('Format'): _t(prettyFormat(format))},
        actions: [
          CodeAction(_t('Search product'), Icons.search,
              uri: Uri.parse(
                  'https://www.google.com/search?q=${Uri.encodeQueryComponent(v)}')),
          CodeAction(_t('Copy number'), Icons.copy, copyText: v),
        ],
      );

  static ParsedCode _wifi(String v) {
    final map = <String, String>{};
    for (final part in _splitEscaped(v.substring(5), ';')) {
      final i = part.indexOf(':');
      if (i > 0) map[part.substring(0, i).toUpperCase()] = part.substring(i + 1);
    }
    final ssid = map['S'] ?? '';
    final pass = map['P'] ?? '';
    final sec = map['T'] ?? '';
    return ParsedCode(
      type: CodeType.wifi,
      raw: v,
      title: ssid.isEmpty ? _t('Wi-Fi network') : ssid,
      fields: {
        _t('Network'): ssid,
        _t('Security'):
            (sec.isEmpty || sec.toLowerCase() == 'nopass')
                ? _t('Open network')
                : sec,
        if (pass.isNotEmpty) _t('Password'): pass,
        if ((map['H'] ?? '').toLowerCase() == 'true') _t('Hidden'): _t('Yes'),
      },
      actions: [
        if (pass.isNotEmpty)
          CodeAction(_t('Copy password'), Icons.key, copyText: pass),
        CodeAction(_t('Copy name'), Icons.wifi, copyText: ssid),
      ],
    );
  }

  static ParsedCode _email(String v) {
    var addr = v;
    var subject = '';
    var body = '';
    final lower = v.toLowerCase();
    if (lower.startsWith('mailto:')) {
      final uri = Uri.tryParse(v);
      addr = uri?.path ?? v.substring(7);
      subject = uri?.queryParameters['subject'] ?? '';
      body = uri?.queryParameters['body'] ?? '';
    } else if (lower.startsWith('matmsg:')) {
      for (final part in _splitEscaped(v.substring(7), ';')) {
        final i = part.indexOf(':');
        if (i < 0) continue;
        final key = part.substring(0, i).toUpperCase();
        final val = part.substring(i + 1);
        if (key == 'TO') addr = val;
        if (key == 'SUB') subject = val;
        if (key == 'BODY') body = val;
      }
    }
    final query = [
      if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
      if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return ParsedCode(
      type: CodeType.email,
      raw: v,
      title: addr,
      fields: {
        _t('To'): addr,
        if (subject.isNotEmpty) _t('Subject'): subject,
        if (body.isNotEmpty) _t('Message'): body,
      },
      actions: [
        CodeAction(_t('Send email'), Icons.email,
            uri: Uri.parse('mailto:$addr${query.isEmpty ? '' : '?$query'}')),
        CodeAction(_t('Copy address'), Icons.copy, copyText: addr),
      ],
    );
  }

  static ParsedCode _phone(String v) {
    final number = v.toLowerCase().startsWith('tel:') ? v.substring(4) : v;
    final dial = number.replaceAll(RegExp(r'[\s\-().]'), '');
    return ParsedCode(
      type: CodeType.phone,
      raw: v,
      title: number,
      fields: {_t('Number'): number},
      actions: [
        CodeAction(_t('Call'), Icons.phone, uri: Uri.parse('tel:$dial')),
        CodeAction(_t('Send SMS'), Icons.sms, uri: Uri.parse('sms:$dial')),
        CodeAction(_t('Copy number'), Icons.copy, copyText: number),
      ],
    );
  }

  static ParsedCode _sms(String v) {
    var number = '';
    var message = '';
    if (v.toLowerCase().startsWith('smsto:')) {
      final rest = v.substring(6);
      final i = rest.indexOf(':');
      number = i < 0 ? rest : rest.substring(0, i);
      message = i < 0 ? '' : rest.substring(i + 1);
    } else {
      final uri = Uri.tryParse(v);
      number = uri?.path ?? v.substring(4);
      message = uri?.queryParameters['body'] ?? '';
    }
    final dial = number.replaceAll(RegExp(r'\s'), '');
    return ParsedCode(
      type: CodeType.sms,
      raw: v,
      title: number,
      fields: {
        _t('To'): number,
        if (message.isNotEmpty) _t('Message'): message,
      },
      actions: [
        CodeAction(_t('Send SMS'), Icons.sms,
            uri: Uri.parse(
                'sms:$dial${message.isEmpty ? '' : '?body=${Uri.encodeComponent(message)}'}')),
        CodeAction(_t('Copy number'), Icons.copy, copyText: number),
      ],
    );
  }

  static ParsedCode _geo(String v) {
    final body = v.substring(4).split('?').first;
    final parts = body.split(',');
    if (parts.length < 2) return _text(v);
    final lat = parts[0].trim();
    final lng = parts[1].trim();
    return ParsedCode(
      type: CodeType.geo,
      raw: v,
      title: '$lat, $lng',
      fields: {_t('Latitude'): lat, _t('Longitude'): lng},
      actions: [
        CodeAction(_t('Open in Maps'), Icons.map,
            uri: Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$lat,$lng')),
        CodeAction(_t('Copy coordinates'), Icons.copy, copyText: '$lat, $lng'),
      ],
    );
  }

  static ParsedCode _contact(String v) {
    final fields = <String, String>{};
    // Adds a field; a repeated label gets a number ("Phone 2").
    void put(String label, String value) {
      value = value.trim();
      if (value.isEmpty) return;
      final shown = _t(label);
      var key = shown;
      var n = 2;
      while (fields.containsKey(key)) {
        key = '$shown $n';
        n++;
      }
      fields[key] = value;
    }

    String? phone;
    String? email;

    if (v.toLowerCase().startsWith('mecard:')) {
      for (final part in _splitEscaped(v.substring(7), ';')) {
        final i = part.indexOf(':');
        if (i < 0) continue;
        final key = part.substring(0, i).toUpperCase();
        final val = part.substring(i + 1);
        switch (key) {
          case 'N':
            final p = val.split(',');
            put('Name', p.length > 1 ? '${p[1]} ${p[0]}' : val);
          case 'TEL':
            phone ??= val.trim();
            put('Phone', val);
          case 'EMAIL':
            email ??= val.trim();
            put('Email', val);
          case 'ORG':
            put('Organization', val);
          case 'ADR':
            put('Address', val.replaceAll(',', ' '));
          case 'URL':
            put('Website', val);
          case 'NOTE':
            put('Note', val);
        }
      }
    } else {
      String? structuredName;
      var hasName = false;
      for (final line in v.split(RegExp(r'\r?\n'))) {
        final i = line.indexOf(':');
        if (i < 0) continue;
        final key = line.substring(0, i).toUpperCase().split(';').first;
        final val = line.substring(i + 1);
        switch (key) {
          case 'FN':
            if (val.trim().isNotEmpty) hasName = true;
            put('Name', val);
          case 'N':
            final p = val.split(';');
            structuredName = [if (p.length > 1) p[1], p[0]]
                .where((s) => s.isNotEmpty)
                .join(' ');
          case 'TEL':
            phone ??= val.trim();
            put('Phone', val);
          case 'EMAIL':
            email ??= val.trim();
            put('Email', val);
          case 'ORG':
            put('Organization', val.replaceAll(';', ' '));
          case 'TITLE':
            put('Job title', val);
          case 'ADR':
            put('Address',
                val.split(';').where((s) => s.trim().isNotEmpty).join(', '));
          case 'URL':
            put('Website', val);
          case 'NOTE':
            put('Note', val);
        }
      }
      if (!hasName && (structuredName ?? '').isNotEmpty) {
        final copy = Map<String, String>.from(fields);
        fields
          ..clear()
          ..[_t('Name')] = structuredName!
          ..addAll(copy);
      }
    }

    final name = fields[_t('Name')];
    final callNumber = phone;
    final mailAddress = email;
    return ParsedCode(
      type: CodeType.contact,
      raw: v,
      title: name ?? callNumber ?? mailAddress ?? _t('Contact'),
      fields: fields,
      actions: [
        if (callNumber != null)
          CodeAction(_t('Call'), Icons.phone,
              uri: Uri.parse(
                  'tel:${callNumber.replaceAll(RegExp(r'[\s\-().]'), '')}')),
        if (mailAddress != null)
          CodeAction(_t('Email'), Icons.email,
              uri: Uri.parse('mailto:$mailAddress')),
        CodeAction(_t('Copy details'), Icons.copy,
            copyText:
                fields.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
      ],
    );
  }

  static ParsedCode _calendar(String v) {
    final fields = <String, String>{};
    for (final line in v.split(RegExp(r'\r?\n'))) {
      final i = line.indexOf(':');
      if (i < 0) continue;
      final key = line.substring(0, i).toUpperCase().split(';').first;
      final val = line.substring(i + 1).trim();
      if (val.isEmpty) continue;
      switch (key) {
        case 'SUMMARY':
          fields[_t('Title')] = val;
        case 'DTSTART':
          fields[_t('Starts')] = _prettyDate(val);
        case 'DTEND':
          fields[_t('Ends')] = _prettyDate(val);
        case 'LOCATION':
          fields[_t('Location')] = val;
        case 'DESCRIPTION':
          fields[_t('Description')] = val;
      }
    }
    final location = fields[_t('Location')];
    return ParsedCode(
      type: CodeType.calendar,
      raw: v,
      title: fields[_t('Title')] ?? _t('Calendar event'),
      fields: fields,
      actions: [
        if (location != null)
          CodeAction(_t('Open location'), Icons.map,
              uri: Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}')),
        CodeAction(_t('Copy details'), Icons.copy,
            copyText:
                fields.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
      ],
    );
  }

  // -------------------------------------------------------------- helpers

  /// 20261105T143000Z -> 2026-11-05 14:30
  static String _prettyDate(String s) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2}))?').firstMatch(s);
    if (m == null) return s;
    final date = '${m[1]}-${m[2]}-${m[3]}';
    return m[4] == null ? date : '$date ${m[4]}:${m[5]}';
  }

  /// Splits [s] on [sep], honouring backslash escapes (used by WIFI:/MECARD:).
  static List<String> _splitEscaped(String s, String sep) {
    final out = <String>[];
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == r'\' && i + 1 < s.length) {
        buf.write(s[i + 1]);
        i++;
      } else if (c == sep) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    out.add(buf.toString());
    return out;
  }
}
