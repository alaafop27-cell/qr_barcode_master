import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/services/settings_controller.dart';
import '../home/home_shell.dart';

/// Three short intro pages, shown only the first time the app is opened.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _Page(
      Icons.qr_code_scanner,
      'Scan anything',
      'QR codes and all common barcodes, live from the camera or from a photo in your gallery.',
    ),
    _Page(
      Icons.qr_code_2,
      'Create your own codes',
      'Make QR codes for links, Wi-Fi, contacts and more, plus Code 128 and EAN barcodes. Save or share them.',
    ),
    _Page(
      Icons.lock_outline,
      'Private and offline',
      'Everything stays on your device. No account, no tracking, and your history is yours to clear.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    final settings = context.read<SettingsController>();
    final nav = Navigator.of(context);
    await settings.setOnboardingDone();
    nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeShell()));
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Opacity(
                  opacity: _isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: _isLast ? null : _finish,
                    child: Text(context.tr('Skip')),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height * 0.6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primaryContainer,
                            ),
                            child: Icon(p.icon,
                                size: 72, color: cs.onPrimaryContainer),
                          ),
                          const SizedBox(height: 40),
                          Text(context.tr(p.title),
                              textAlign: TextAlign.center,
                              style: text.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 14),
                          Text(context.tr(p.body),
                              textAlign: TextAlign.center,
                              style: text.bodyLarge
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _index ? cs.primary : cs.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(context.tr(_isLast ? 'Get started' : 'Next')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
