/// Local 1D barcode encoder: Code 128, EAN-13 and EAN-8.
/// Pure Dart (no packages): it only produces a list of bars/spaces that
/// [BarcodeView] paints.

enum BarcodeKind { code128, ean13, ean8 }

extension BarcodeKindX on BarcodeKind {
  String get label => switch (this) {
        BarcodeKind.code128 => 'Code 128',
        BarcodeKind.ean13 => 'EAN-13',
        BarcodeKind.ean8 => 'EAN-8',
      };

  /// Same names as mobile_scanner's BarcodeFormat, so history/results match.
  String get formatName => switch (this) {
        BarcodeKind.code128 => 'code128',
        BarcodeKind.ean13 => 'ean13',
        BarcodeKind.ean8 => 'ean8',
      };

  String get hint => switch (this) {
        BarcodeKind.code128 =>
          'Letters, digits and symbols (English), up to 20 characters',
        BarcodeKind.ean13 =>
          '12 digits - the 13th (check) digit is added automatically',
        BarcodeKind.ean8 =>
          '7 digits - the 8th (check) digit is added automatically',
      };

  bool get digitsOnly => this != BarcodeKind.code128;

  int get maxLength => switch (this) {
        BarcodeKind.code128 => 20,
        BarcodeKind.ean13 => 13,
        BarcodeKind.ean8 => 8,
      };
}

/// Result of encoding: the text to print and the bar pattern.
class EncodedBarcode {
  final BarcodeKind kind;

  /// Final text (for EAN: includes the check digit).
  final String data;

  /// `true` = bar, `false` = space. Does NOT include the quiet zones.
  final List<bool> modules;

  const EncodedBarcode(this.kind, this.data, this.modules);
}

class BarcodeEncoder {
  BarcodeEncoder._();

  /// Maps a scanner/history format name to a kind we can draw.
  static BarcodeKind? kindFromFormat(String format) {
    for (final k in BarcodeKind.values) {
      if (k.formatName == format) return k;
    }
    return null;
  }

  /// Error message for the user, or null when [input] is valid.
  /// Pass `tr: context.tr` to get the message in the current language.
  static String? validate(
    BarcodeKind kind,
    String input, {
    String Function(String)? tr,
  }) {
    try {
      encode(kind, input);
      return null;
    } on FormatException catch (e) {
      final translate = tr ?? (String s) => s;
      var message = translate(e.message);
      // "{n}" is replaced by the value carried in `source` (e.g. check digit).
      final extra = e.source;
      if (extra is String) message = message.replaceAll('{n}', extra);
      return message;
    }
  }

  /// Like [encode] but returns null instead of throwing.
  static EncodedBarcode? tryEncode(BarcodeKind kind, String input) {
    try {
      return encode(kind, input);
    } on FormatException {
      return null;
    }
  }

  static EncodedBarcode encode(BarcodeKind kind, String input) {
    final v = input.trim();
    return switch (kind) {
      BarcodeKind.code128 => _code128(v),
      BarcodeKind.ean13 => _ean13(v),
      BarcodeKind.ean8 => _ean8(v),
    };
  }

  // ------------------------------------------------------------- EAN / UPC

  static const List<String> _eanL = [
    '0001101', '0011001', '0010011', '0111101', '0100011',
    '0110001', '0101111', '0111011', '0110111', '0001011',
  ];

  // R = complement of L;  G = R reversed.
  static String _r(String l) =>
      l.split('').map((c) => c == '0' ? '1' : '0').join();
  static String _g(String l) => _r(l).split('').reversed.join();

  // Which table (L/G) the 6 left digits use, selected by the first digit.
  static const List<String> _eanParity = [
    'LLLLLL', 'LLGLGG', 'LLGGLG', 'LLGGGL', 'LGLLGG',
    'LGGLLG', 'LGGGLL', 'LGLGLG', 'LGLGGL', 'LGGLGL',
  ];

  /// Check digit for the digits in [body] (rightmost digit has weight 3).
  static int _checkDigit(String body) {
    var sum = 0;
    for (var i = 0; i < body.length; i++) {
      final digit = int.parse(body[body.length - 1 - i]);
      sum += digit * (i.isEven ? 3 : 1);
    }
    return (10 - sum % 10) % 10;
  }

  /// Validates length / digits / check digit and returns the full number.
  static String _eanFull(String v, int length) {
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      throw const FormatException('Digits only');
    }
    if (v.length != length - 1 && v.length != length) {
      throw FormatException(length == 13
          ? 'Enter 12 digits (or all 13 including the check digit)'
          : 'Enter 7 digits (or all 8 including the check digit)');
    }
    final body = v.substring(0, length - 1);
    final check = _checkDigit(body);
    if (v.length == length && int.parse(v[length - 1]) != check) {
      throw FormatException(
          'Wrong check digit (it should be {n})', check.toString());
    }
    return '$body$check';
  }

  static List<bool> _bits(String s) => s.split('').map((c) => c == '1').toList();

  static EncodedBarcode _ean13(String v) {
    final full = _eanFull(v, 13);
    final parity = _eanParity[int.parse(full[0])];
    final sb = StringBuffer('101');
    for (var i = 0; i < 6; i++) {
      final l = _eanL[int.parse(full[i + 1])];
      sb.write(parity[i] == 'L' ? l : _g(l));
    }
    sb.write('01010');
    for (var i = 7; i < 13; i++) {
      sb.write(_r(_eanL[int.parse(full[i])]));
    }
    sb.write('101');
    return EncodedBarcode(BarcodeKind.ean13, full, _bits(sb.toString()));
  }

  static EncodedBarcode _ean8(String v) {
    final full = _eanFull(v, 8);
    final sb = StringBuffer('101');
    for (var i = 0; i < 4; i++) {
      sb.write(_eanL[int.parse(full[i])]);
    }
    sb.write('01010');
    for (var i = 4; i < 8; i++) {
      sb.write(_r(_eanL[int.parse(full[i])]));
    }
    sb.write('101');
    return EncodedBarcode(BarcodeKind.ean8, full, _bits(sb.toString()));
  }

  // ------------------------------------------------------------- Code 128

  /// Bar/space widths of symbol values 0..106 (bar first, 6 widths each;
  /// the stop symbol 106 has 7 widths).
  static const List<String> _c128 = [
    '212222', '222122', '222221', '121223', '121322', '131222', '122213',
    '122312', '132212', '221213', '221312', '231212', '112232', '122132',
    '122231', '113222', '123122', '123221', '223211', '221132', '221231',
    '213212', '223112', '312131', '311222', '321122', '321221', '312212',
    '322112', '322211', '212123', '212321', '232121', '111323', '131123',
    '131321', '112313', '132113', '132311', '211313', '231113', '231311',
    '112133', '112331', '132131', '113123', '113321', '133121', '313121',
    '211331', '231131', '213113', '213311', '213131', '311123', '311321',
    '331121', '312113', '312311', '332111', '314111', '221411', '431111',
    '111224', '111422', '121124', '121421', '141122', '141221', '112214',
    '112412', '122114', '122411', '142112', '142211', '241211', '221114',
    '413111', '241112', '134111', '111242', '121142', '121241', '114212',
    '124112', '124211', '411212', '421112', '421211', '212141', '214121',
    '412121', '111143', '111341', '131141', '114113', '114311', '411113',
    '411311', '113141', '114131', '311141', '411131', '211412', '211214',
    '211232', '2331112',
  ];

  static EncodedBarcode _code128(String v) {
    if (v.isEmpty) throw const FormatException('Enter some text');
    if (v.length > 20) throw const FormatException('Maximum 20 characters');

    final values = <int>[];
    int start;
    final numericPairs = RegExp(r'^\d+$').hasMatch(v) && v.length.isEven;
    if (numericPairs) {
      // Code set C packs two digits per symbol (shorter barcode).
      start = 105;
      for (var i = 0; i < v.length; i += 2) {
        values.add(int.parse(v.substring(i, i + 2)));
      }
    } else {
      // Code set B: ASCII 32..126.
      start = 104;
      for (final c in v.codeUnits) {
        if (c < 32 || c > 126) {
          throw const FormatException(
              'Only English letters, digits and symbols are supported');
        }
        values.add(c - 32);
      }
    }

    var sum = start;
    for (var i = 0; i < values.length; i++) {
      sum += values[i] * (i + 1);
    }
    final symbols = <int>[start, ...values, sum % 103, 106];

    final modules = <bool>[];
    for (final s in symbols) {
      final widths = _c128[s];
      for (var i = 0; i < widths.length; i++) {
        final w = int.parse(widths[i]);
        final isBar = i.isEven;
        for (var k = 0; k < w; k++) {
          modules.add(isBar);
        }
      }
    }
    return EncodedBarcode(BarcodeKind.code128, v, modules);
  }
}
