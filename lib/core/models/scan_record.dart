enum ScanSource { scanned, generated }

/// One entry in the history (either scanned or generated).
class ScanRecord {
  final String id;
  final String rawValue;

  /// BarcodeFormat name, e.g. `qrCode`, `ean13`, `code128`.
  final String format;
  final ScanSource source;
  final DateTime createdAt;
  final bool favorite;

  const ScanRecord({
    required this.id,
    required this.rawValue,
    required this.format,
    required this.source,
    required this.createdAt,
    this.favorite = false,
  });

  factory ScanRecord.create({
    required String rawValue,
    required String format,
    required ScanSource source,
  }) {
    final now = DateTime.now();
    return ScanRecord(
      id: now.microsecondsSinceEpoch.toString(),
      rawValue: rawValue,
      format: format,
      source: source,
      createdAt: now,
    );
  }

  ScanRecord copyWith({bool? favorite}) => ScanRecord(
        id: id,
        rawValue: rawValue,
        format: format,
        source: source,
        createdAt: createdAt,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'raw': rawValue,
        'format': format,
        'source': source.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'favorite': favorite,
      };

  factory ScanRecord.fromMap(Map<String, dynamic> m) => ScanRecord(
        id: m['id'] as String,
        rawValue: m['raw'] as String,
        format: (m['format'] as String?) ?? 'qrCode',
        source: m['source'] == 'generated'
            ? ScanSource.generated
            : ScanSource.scanned,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        favorite: (m['favorite'] as bool?) ?? false,
      );
}
