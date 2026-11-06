import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n/app_strings.dart';
import 'core/services/settings_controller.dart';
import 'features/splash/splash_screen.dart';

class QrApp extends StatelessWidget {
  const QrApp({super.key});

  ThemeData _theme(Color seed, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      onGenerateTitle: (context) => context.tr('QR & Barcode Master'),
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _theme(settings.seedColor, Brightness.light),
      darkTheme: _theme(settings.seedColor, Brightness.dark),

      // Language follows the device: Arabic (right-to-left) or English.
      // Any other device language falls back to English.
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(),
    );
  }
}
