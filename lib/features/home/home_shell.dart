import 'package:flutter/material.dart';

import '../../core/ads/banner_ad_widget.dart';
import '../generator/generator_screen.dart';
import '../history/history_screen.dart';
import '../scanner/scanner_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom navigation + persistent banner slot.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // The camera is only alive while the Scan tab is visible
    // (saves battery and releases the camera for other apps).
    final pages = <Widget>[
      _index == 0 ? const ScannerScreen() : const SizedBox.shrink(),
      const GeneratorScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(), // renders nothing until ads are configured
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_2),
                label: 'Create',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
