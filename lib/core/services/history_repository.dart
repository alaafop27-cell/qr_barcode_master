import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/scan_record.dart';

/// Local history storage on top of Hive (no code generation needed).
/// Records are stored as plain maps, newest first in memory.
class HistoryRepository extends ChangeNotifier {
  static const String _boxName = 'history';
  static const int maxItems = 500;

  late final Box _box;
  List<ScanRecord> _items = [];

  List<ScanRecord> get items => List.unmodifiable(_items);

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _items = _box.values
        .map((e) => ScanRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> add(ScanRecord record) async {
    await _box.put(record.id, record.toMap());
    _items.add(record);
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    while (_items.length > maxItems) {
      final removed = _items.removeLast();
      await _box.delete(removed.id);
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _items.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final updated = _items[index].copyWith(favorite: !_items[index].favorite);
    _items[index] = updated;
    await _box.put(id, updated.toMap());
    notifyListeners();
  }

  Future<void> clear() async {
    await _box.clear();
    _items.clear();
    notifyListeners();
  }
}
