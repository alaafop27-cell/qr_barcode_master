import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// App settings persisted locally in a Hive box.
class SettingsController extends ChangeNotifier {
  static const String _boxName = 'settings';

  /// Colors offered in the theme picker (Material 3 seed colors).
  static const List<Color> presetColors = [
    Color(0xFF2979FF), // blue (default)
    Color(0xFF00B0FF), // light blue
    Color(0xFF3949AB), // indigo
    Color(0xFF8E24AA), // purple
    Color(0xFFD81B60), // pink
    Color(0xFFE53935), // red
    Color(0xFFF4511E), // orange
    Color(0xFFFFB300), // amber
    Color(0xFF43A047), // green
    Color(0xFF00897B), // teal
    Color(0xFF6D4C41), // brown
    Color(0xFF546E7A), // blue grey
  ];

  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Color get seedColor =>
      Color(_box.get('seed', defaultValue: 0xFF2979FF) as int);

  ThemeMode get themeMode =>
      ThemeMode.values[(_box.get('theme', defaultValue: 0) as int)
          .clamp(0, ThemeMode.values.length - 1)
          .toInt()];

  bool get sound => _box.get('sound', defaultValue: true) as bool;
  bool get vibration => _box.get('vibration', defaultValue: true) as bool;
  bool get saveHistory => _box.get('saveHistory', defaultValue: true) as bool;

  Future<void> setSeedColor(Color c) => _put('seed', c.value);
  Future<void> setThemeMode(ThemeMode m) => _put('theme', m.index);
  Future<void> setSound(bool v) => _put('sound', v);
  Future<void> setVibration(bool v) => _put('vibration', v);
  Future<void> setSaveHistory(bool v) => _put('saveHistory', v);

  Future<void> _put(String key, Object value) async {
    await _box.put(key, value);
    notifyListeners();
  }
}
