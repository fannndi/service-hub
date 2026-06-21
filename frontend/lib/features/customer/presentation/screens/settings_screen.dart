import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../ui/widgets/modern_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final url = EnvironmentService.currentUrl;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: GradientBackground(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Server',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: Icon(
                url.contains('trycloudflare.com') ? Icons.cloud : Icons.computer,
                color: url.contains('trycloudflare.com')
                    ? AppColors.secondary
                    : AppColors.success,
              ),
              title: const Text('API Server'),
              subtitle: Text(
                url,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Tentang',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.w700)),
            ),
            const ListTile(
              leading: Icon(Icons.build),
              title: Text('ServisGadget'),
              subtitle: Text('Platform Marketplace Servis Gadget'),
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('Versi'),
              subtitle: Text('1.0.0'),
            ),
          ],
        ),
      ),
    );
  }
}
