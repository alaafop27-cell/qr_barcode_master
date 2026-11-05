import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/settings_controller.dart';
import 'features/home/home_shell.dart';

class QrApp extends StatelessWidget {
  const QrApp({super.key});

  ThemeData _theme(Color seed, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      appBarTheme: const AppBarTheme(centerTitle: true),
      cardTheme: const CardTheme(margin: EdgeInsets.zero),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return MaterialApp(
      title: 'QR & Barcode Master',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _theme(settings.seedColor, Brightness.light),
      darkTheme: _theme(settings.seedColor, Brightness.dark),
      home: const HomeShell(),
    );
  }
}
