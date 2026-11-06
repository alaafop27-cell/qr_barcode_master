/// Builds the text that gets encoded into a generated QR code, using the
/// standard formats every phone scanner understands.
class QrPayloads {
  QrPayloads._();

  static String text(String v) => v.trim();

  static String url(String v) {
    final t = v.trim();
    return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').hasMatch(t)
        ? t
        : 'https://$t';
  }

  static String phone(String v) => 'tel:${v.trim().replaceAll(' ', '')}';

  static String email({
    required String address,
    String subject = '',
    String body = '',
  }) {
    final query = [
      if (subject.trim().isNotEmpty)
        'subject=${Uri.encodeComponent(subject.trim())}',
      if (body.trim().isNotEmpty) 'body=${Uri.encodeComponent(body.trim())}',
    ].join('&');
    return 'mailto:${address.trim()}${query.isEmpty ? '' : '?$query'}';
  }

  static String sms({required String number, String message = ''}) =>
      'SMSTO:${number.trim().replaceAll(' ', '')}:${message.trim()}';

  static String geo({required String lat, required String lng}) =>
      'geo:${lat.trim()},${lng.trim()}';

  /// security: 'WPA' | 'WEP' | 'nopass'
  static String wifi({
    required String ssid,
    required String password,
    required String security,
    required bool hidden,
  }) {
    String esc(String s) =>
        s.replaceAllMapped(RegExp(r'([\\;,":])'), (m) => '\\${m[1]}');
    final pass = security == 'nopass' ? '' : 'P:${esc(password)};';
    return 'WIFI:T:$security;S:${esc(ssid)};$pass${hidden ? 'H:true;' : ''};';
  }

  static String vCard({
    required String name,
    String phone = '',
    String email = '',
    String organization = '',
  }) {
    return [
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${name.trim()}',
      'N:${name.trim()};;;;',
      if (organization.trim().isNotEmpty) 'ORG:${organization.trim()}',
      if (phone.trim().isNotEmpty) 'TEL:${phone.trim()}',
      if (email.trim().isNotEmpty) 'EMAIL:${email.trim()}',
      'END:VCARD',
    ].join('\n');
  }
}
