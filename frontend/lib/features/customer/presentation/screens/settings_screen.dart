import 'package:flutter/material.dart';
import '../../../../core/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currentEnvironment;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEnvironment = EnvironmentService.currentEnv;
  }

  Future<void> _switchEnvironment(String env) async {
    setState(() => _isLoading = true);
    
    await EnvironmentService.setEnvironment(env);
    
    setState(() {
      _currentEnvironment = env;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beralih ke environment: ${env == 'local' ? 'Local' : 'Production'}'),
          backgroundColor: env == 'local' ? Colors.green : Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildEnvironmentSection(),
                const Divider(),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildEnvironmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Environment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        RadioListTile<String>(
          title: const Text('Local (Docker)'),
          subtitle: const Text('localhost:3000'),
          value: 'local',
          groupValue: _currentEnvironment,
          onChanged: (value) => _switchEnvironment(value!),
          activeColor: Colors.green,
        ),
        RadioListTile<String>(
          title: const Text('Production (Supabase)'),
          subtitle: const Text('api.servisgadget.com'),
          value: 'production',
          groupValue: _currentEnvironment,
          onChanged: (value) => _switchEnvironment(value!),
          activeColor: Colors.blue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _currentEnvironment == 'local' ? Icons.computer : Icons.cloud,
                  color: _currentEnvironment == 'local' ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentEnvironment == 'local' ? 'Local Development' : 'Production',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currentEnvironment == 'local'
                            ? 'Menggunakan Docker di WSL'
                            : 'Menggunakan Supabase + SumoPod',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang ServisGadget'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform Marketplace Servis Gadget Dua Sisi'),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            Text('Build: 2026-06-17'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
