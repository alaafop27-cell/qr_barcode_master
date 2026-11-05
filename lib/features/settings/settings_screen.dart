import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/history_repository.dart';
import '../../core/services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(t, style: text.titleSmall?.copyWith(color: cs.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.setThemeMode(v.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in SettingsController.presetColors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => s.setSeedColor(c),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: c,
                      child: s.seedColor.value == c.value
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          header('Scanning'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Beep on scan'),
            value: s.sound,
            onChanged: s.setSound,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibrate on scan'),
            value: s.vibration,
            onChanged: s.setVibration,
          ),
          const Divider(),
          header('Data'),
          SwitchListTile(
            secondary: const Icon(Icons.history),
            title: const Text('Save history'),
            subtitle: const Text('Scanned and generated codes stay on this device'),
            value: s.saveHistory,
            onChanged: s.setSaveHistory,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear history'),
            onTap: () async {
              final repo = context.read<HistoryRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear history?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear')),
                  ],
                ),
              );
              if (yes == true) {
                await repo.clear();
                messenger.showSnackBar(
                    const SnackBar(content: Text('History cleared')));
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('QR & Barcode Master'),
            subtitle: Text('Version 1.0.0 - works fully offline'),
          ),
        ],
      ),
    );
  }
}
