import 'package:flutter/material.dart';
import '../../../../core/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final sb = SupabaseService.instance;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akun', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(sb.user?.email ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('Role: ${sb.role ?? '-'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aplikasi', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('ServisGadget v2.0', style: Theme.of(context).textTheme.bodyMedium),
                Text('Powered by Supabase', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
