import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'ar_strings.dart';

/// Tiny translation system (English / Arabic) that follows the device language.
///
/// English text is used as the key, so a missing Arabic entry simply shows the
/// English text instead of breaking anything.
///
///   Text(context.tr('Scan now'))
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('en'));

  String tr(String key) => isArabic ? (arStrings[key] ?? key) : key;

  /// e.g. "Nov 5, 2026 14:30"  /  "٥ نوفمبر ٢٠٢٦ ١٤:٣٠"
  String dateTime(DateTime d) => _format(
        () => DateFormat.yMMMd(locale.languageCode).add_Hm().format(d),
        d,
      );

  /// e.g. "Nov 5 14:30"
  String shortDateTime(DateTime d) => _format(
        () => DateFormat.MMMd(locale.languageCode).add_Hm().format(d),
        d,
      );

  /// Uses the localized format; if the date data for the language is not
  /// available for any reason, falls back to plain "2026-11-05 14:30".
  String _format(String Function() localized, DateTime d) {
    try {
      return localized();
    } catch (_) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    }
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture<AppStrings>(AppStrings(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

extension AppStringsContext on BuildContext {
  /// Translate an English UI string to the current language.
  String tr(String key) => AppStrings.of(this).tr(key);

  AppStrings get strings => AppStrings.of(this);
}
