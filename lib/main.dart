import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/services/history_repository.dart';
import 'core/services/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Date formats for every language (needed for Arabic dates).
  await initializeDateFormatting();

  // Local storage
  await Hive.initFlutter();
  final settings = SettingsController();
  final history = HistoryRepository();
  await settings.init();
  await history.init();

  // Ads: no-op until IDs are provided in lib/core/ads/ad_config.dart
  await AdService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: history),
      ],
      child: const QrApp(),
    ),
  );
}
