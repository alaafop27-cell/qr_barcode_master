import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
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
          child: Text(context.tr(t),
              style: text.titleSmall?.copyWith(color: cs.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: ListView(
        children: [
          header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto),
                    label: Text(context.tr('System'))),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode),
                    label: Text(context.tr('Light'))),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(context.tr('Dark'))),
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
            title: Text(context.tr('Beep on scan')),
            value: s.sound,
            onChanged: s.setSound,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(context.tr('Vibrate on scan')),
            value: s.vibration,
            onChanged: s.setVibration,
          ),
          const Divider(),
          header('Data'),
          SwitchListTile(
            secondary: const Icon(Icons.history),
            title: Text(context.tr('Save history')),
            subtitle: Text(
                context.tr('Scanned and generated codes stay on this device')),
            value: s.saveHistory,
            onChanged: s.setSaveHistory,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(context.tr('Clear history')),
            onTap: () async {
              final repo = context.read<HistoryRepository>();
              final messenger = ScaffoldMessenger.of(context);
              final cleared = context.tr('History cleared');
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(ctx.tr('Clear history?')),
                  content: Text(ctx.tr('This cannot be undone.')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(ctx.tr('Cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(ctx.tr('Clear'))),
                  ],
                ),
              );
              if (yes == true) {
                await repo.clear();
                messenger.showSnackBar(SnackBar(content: Text(cleared)));
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.tr('QR & Barcode Master')),
            subtitle: Text(context.tr('Version 1.3.0 - works fully offline')),
          ),
        ],
      ),
    );
  }
}
