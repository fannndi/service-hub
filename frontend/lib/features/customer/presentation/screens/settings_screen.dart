import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final url = EnvironmentService.currentUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Server',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              url.contains('trycloudflare.com') ? Icons.cloud : Icons.computer,
              color: url.contains('trycloudflare.com') ? Colors.blue : Colors.green,
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
            child: Text(
              'Tentang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('ServisGadget'),
            subtitle: const Text('Platform Marketplace Servis Gadget'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versi'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
