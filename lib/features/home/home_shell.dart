import 'package:flutter/material.dart';

import '../../core/ads/banner_ad_widget.dart';
import '../../core/l10n/app_strings.dart';
import '../generator/generator_screen.dart';
import '../history/history_screen.dart';
import '../scanner/scanner_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Bottom navigation (Home, Scan, Create, History, Settings) + banner slot.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _autoPickImage = false;
  GenType _genType = GenType.text;
  bool _genBarcode = false;
  int _genToken = 0; // changes -> generator is rebuilt with the new type

  void _select(int i) => setState(() {
        _autoPickImage = false;
        _index = i;
      });

  void _goScan({bool pickImage = false}) => setState(() {
        _autoPickImage = pickImage;
        _index = 1;
      });

  void _goCreate(GenType t) => setState(() {
        _genType = t;
        _genBarcode = false;
        _genToken++;
        _index = 2;
      });

  void _goCreateBarcode() => setState(() {
        _genBarcode = true;
        _genToken++;
        _index = 2;
      });

  @override
  Widget build(BuildContext context) {
    // The camera is only alive while the Scan tab is visible
    // (saves battery and releases the camera for other apps).
    final pages = <Widget>[
      HomeScreen(
        onScan: _goScan,
        onScanImage: () => _goScan(pickImage: true),
        onCreate: _goCreate,
        onCreateBarcode: _goCreateBarcode,
        onOpenHistory: () => _select(3),
      ),
      _index == 1
          ? ScannerScreen(autoPickImage: _autoPickImage)
          : const SizedBox.shrink(),
      GeneratorScreen(
        key: ValueKey(_genToken),
        initialType: _genType,
        initialBarcode: _genBarcode,
      ),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      // Back button on any other tab returns to Home instead of closing the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BannerAdWidget(), // renders nothing until ads are configured
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: context.tr('Home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: context.tr('Scan'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_2),
                  label: context.tr('Create'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history),
                  label: context.tr('History'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: context.tr('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
