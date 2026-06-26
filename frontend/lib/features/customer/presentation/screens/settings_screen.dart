import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/theme/app_decorations.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final scheme = theme.colorScheme;
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: GradientBackground(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.settings, size: 36, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.language, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SegmentedButton<Locale>(
                  segments: const [
                    ButtonSegment(value: Locale('id'), label: Text('Indonesia'), icon: Icon(Icons.language)),
                    ButtonSegment(value: Locale('en'), label: Text('English'), icon: Icon(Icons.language)),
                  ],
                  selected: {currentLocale},
                  onSelectionChanged: (v) => ref.read(localeProvider.notifier).setLocale(v.first),
                  showSelectedIcon: false,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.theme, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Terang'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Gelap'), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {currentTheme == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light},
                  onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v.first),
                  showSelectedIcon: false,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.support_agent, color: Colors.green),
              ),
              title: Text(l.adminHelp),
              subtitle: Text(l.adminHelpSubtitle),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(Uri.parse('https://wa.me/6285700375224'), mode: LaunchMode.externalApplication),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.application, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(l.appVersion, style: theme.textTheme.bodyMedium),
                Text(l.poweredBy, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
